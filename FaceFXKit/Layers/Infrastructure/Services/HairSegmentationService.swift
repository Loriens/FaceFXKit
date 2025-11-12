//
//  HairSegmentationService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 29/07/2025.
//

import Foundation
import UIKit
@preconcurrency import CoreImage
@preconcurrency import CoreML
import Vision

protocol HairSegmentationService {
    func segmentHair(in ciImage: CIImage) async throws -> HairSegmentationResult
}

actor DefaultHairSegmentationService: HairSegmentationService {
    struct SegmentationMultiArray {
        let mlMultiArray: MLMultiArray
        let width: Int
        let height: Int

        init(mlMultiArray: MLMultiArray) {
            self.mlMultiArray = mlMultiArray
            self.width = mlMultiArray.shape[0].intValue
            self.height = mlMultiArray.shape[1].intValue
        }

        subscript(x: Int, y: Int) -> NSNumber {
            let index = x * height + y
            return mlMultiArray[index]
        }
    }

    private let model: FaceParsing
    private let context: CIContext
    private let modelInputSize: CGSize = CGSize(width: 512, height: 512)
    
    init() throws {
        do {
            self.context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])

            let configuration = MLModelConfiguration()
            configuration.computeUnits = .cpuAndGPU
            self.model = try FaceParsing(configuration: configuration)
        } catch {
            throw HairSegmentationError.modelLoadingFailed
        }
    }
    
    func segmentHair(in ciImage: CIImage) async throws -> HairSegmentationResult {
        let resizedImage = prepareImageForModel(ciImage)
        let pixelBuffer = try createPixelBuffer(from: resizedImage)

        let prediction = try await runModelPrediction(pixelBuffer: pixelBuffer)

        let hairMask = try extractHairMask(from: prediction)
        let scaledMask = scaleMaskToOriginalSize(hairMask, originalSize: ciImage.extent.size)

        let blurFilter = CIFilter(name: "CIGaussianBlur")!
        blurFilter.setValue(scaledMask, forKey: kCIInputImageKey)
        blurFilter.setValue(10.0, forKey: kCIInputRadiusKey)

        let blurredMask = blurFilter.outputImage ?? scaledMask
        
        return HairSegmentationResult(
            imageSize: ciImage.extent.size,
            hairMask: blurredMask,
            originalHairMask: scaledMask,
            processedAt: Date()
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func prepareImageForModel(_ ciImage: CIImage) -> CIImage {
        let sourceSize = ciImage.extent.size
        let targetSize = modelInputSize

        let scaleX = targetSize.width / sourceSize.width
        let scaleY = targetSize.height / sourceSize.height

        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let cropRect = CGRect(
            x: 0,
            y: 0,
            width: targetSize.width,
            height: targetSize.height
        )
        
        return scaledImage.cropped(to: cropRect)
    }
    
    private func createPixelBuffer(from ciImage: CIImage) throws -> CVPixelBuffer {
        let pixelFormat: OSType = kCVPixelFormatType_32BGRA
        let targetSize = ciImage.extent.size
        var pixelBuffer: CVPixelBuffer?

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
            kCVPixelBufferWidthKey as String: Int(targetSize.width),
            kCVPixelBufferHeightKey as String: Int(targetSize.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        CVPixelBufferCreate(
            nil,
            Int(targetSize.width),
            Int(targetSize.height),
            pixelFormat,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard let pixelBuffer else {
            throw HairSegmentationError.processingFailed("Failed to create pixel buffer")
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        context.render(
            ciImage,
            to: pixelBuffer,
            bounds: ciImage.extent,
            colorSpace: colorSpace
        )

        return pixelBuffer
    }
    
    private func runModelPrediction(pixelBuffer: CVPixelBuffer) async throws -> MLFeatureProvider {
        let input = FaceParsingInput(input: pixelBuffer)
        let prediction = try await model.prediction(input: input)
        return prediction
    }
    
    private func extractHairMask(from prediction: MLFeatureProvider) throws -> CIImage {
        guard
            let outputFeature = prediction.featureValue(for: "455"),
            let multiArray = outputFeature.multiArrayValue
        else {
            throw HairSegmentationError.processingFailed("Invalid model output format")
        }

        let hairMask = try createHairMaskFromMultiArray(multiArray)
        
        return hairMask
    }
    
    private func createHairMaskFromMultiArray(_ multiArray: MLMultiArray) throws -> CIImage {
        let segmentationResult = SegmentationMultiArray(mlMultiArray: multiArray)
        let width = segmentationResult.width
        let height = segmentationResult.height

        var maskData = Data(count: width * height)
        
        maskData.withUnsafeMutableBytes { bytes in
            let pixelPtr = bytes.bindMemory(to: UInt8.self)
            
            for x in 0..<width {
                for y in 0..<height {
                    // Get the segmentation class for this pixel
                    let segmentationClass = segmentationResult[x, y].intValue
                    
                    // Hair class is index 17
                    let isHair = segmentationClass == 17
                    
                    // Convert to binary mask
                    let pixelIndex = x * height + y
                    pixelPtr[pixelIndex] = isHair ? 255 : 0
                }
            }
        }

        guard let dataProvider = CGDataProvider(data: maskData as CFData) else {
            throw HairSegmentationError.processingFailed("Failed to create data provider")
        }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw HairSegmentationError.processingFailed("Failed to create CGImage from mask")
        }
        
        return CIImage(cgImage: cgImage)
    }
    
    private func scaleMaskToOriginalSize(_ mask: CIImage, originalSize: CGSize) -> CIImage {
        let scaleX = originalSize.width / mask.extent.width
        let scaleY = originalSize.height / mask.extent.height
        
        return mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

// MARK: - Helper Extensions

private extension CIImage {
    func pixelColor(at point: CGPoint, context: CIContext) -> (red: Float, green: Float, blue: Float, alpha: Float) {
        let bitmap = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        defer { bitmap.deallocate() }
        
        let rect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
        context.render(self, toBitmap: bitmap, rowBytes: 4, bounds: rect, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        return (
            red: Float(bitmap[0]) / 255.0,
            green: Float(bitmap[1]) / 255.0,
            blue: Float(bitmap[2]) / 255.0,
            alpha: Float(bitmap[3]) / 255.0
        )
    }
}
