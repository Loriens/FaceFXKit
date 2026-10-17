//
//  HairSegmentationService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 29/07/2025.
//

@preconcurrency import CoreImage
@preconcurrency import CoreML

protocol HairSegmentationService {
    func segmentHair(in ciImage: CIImage) async throws -> HairSegmentationResult
}

actor DefaultHairSegmentationService: HairSegmentationService {
    private let model: FaceParsing
    private let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
    private let modelInputSize = CGSize(width: 512, height: 512)

    /// Name of the FaceParsing model's segmentation output layer.
    private static let segmentationOutputFeatureName = "455"
    /// Index of the "hair" class in the FaceParsing segmentation map.
    private static let hairClassIndex = 17

    init() throws {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndGPU

        do {
            model = try FaceParsing(configuration: configuration)
        } catch {
            throw HairSegmentationError.modelLoadingFailed
        }
    }

    func segmentHair(in ciImage: CIImage) async throws -> HairSegmentationResult {
        let imageSize = ciImage.extent.size
        let pixelBuffer = try makePixelBuffer(from: resized(ciImage, to: modelInputSize))

        try Task.checkCancellation()
        let prediction = try await model.prediction(input: FaceParsingInput(input: pixelBuffer))
        try Task.checkCancellation()

        let mask = try resized(hairMask(from: prediction), to: imageSize)

        let blur = CIFilter(name: "CIGaussianBlur")!
        blur.setValue(mask, forKey: kCIInputImageKey)
        blur.setValue(10.0, forKey: kCIInputRadiusKey)

        return HairSegmentationResult(
            imageSize: imageSize,
            hairMask: blur.outputImage ?? mask,
            originalHairMask: mask,
            processedAt: Date()
        )
    }

    // MARK: - Private Helper Methods

    private func resized(_ image: CIImage, to size: CGSize) -> CIImage {
        let scaleX = size.width / image.extent.width
        let scaleY = size.height / image.extent.height

        return image
            .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            .cropped(to: CGRect(origin: .zero, size: size))
    }

    private func makePixelBuffer(from image: CIImage) throws -> CVPixelBuffer {
        let width = Int(image.extent.width)
        let height = Int(image.extent.height)
        let attributes: [String: Any] = [kCVPixelBufferIOSurfacePropertiesKey as String: [:]]

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attributes as CFDictionary, &pixelBuffer)

        guard let pixelBuffer else {
            throw HairSegmentationError.processingFailed("Failed to create pixel buffer")
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        context.render(image, to: pixelBuffer, bounds: image.extent, colorSpace: colorSpace)
        return pixelBuffer
    }

    private func hairMask(from prediction: MLFeatureProvider) throws -> CIImage {
        guard let classMap = prediction.featureValue(for: Self.segmentationOutputFeatureName)?.multiArrayValue else {
            throw HairSegmentationError.processingFailed("Invalid model output format")
        }

        let width = classMap.shape[0].intValue
        let height = classMap.shape[1].intValue
        var maskData = Data(count: width * height)

        try maskData.withUnsafeMutableBytes { bytes in
            let pixels = bytes.bindMemory(to: UInt8.self)

            for x in 0..<width {
                // The 512×512 scan is the slowest CPU part of segmentation —
                // bail out promptly when the caller has moved on.
                try Task.checkCancellation()

                for y in 0..<height {
                    let index = x * height + y
                    pixels[index] = classMap[index].intValue == Self.hairClassIndex ? 255 : 0
                }
            }
        }

        guard
            let provider = CGDataProvider(data: maskData as CFData),
            let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else {
            throw HairSegmentationError.processingFailed("Failed to create CGImage from mask")
        }

        return CIImage(cgImage: cgImage)
    }
}
