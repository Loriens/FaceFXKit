//
//  FilterProcessingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import Metal
import MetalKit
import CoreImage
import Vision

protocol FilterProcessingService {
    func applyFilters(
        to image: CIImage,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) throws -> CIImage
}

final class DefaultFilterProcessingService: FilterProcessingService, @unchecked Sendable {
    private let context: CIContext
    
    init(ciContextStore: CIContextStore) {
        self.context = ciContextStore.primaryContext
    }
    
    func applyFilters(
        to image: CIImage,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) throws -> CIImage {
        try processImage(image, with: configuration, detectionData: detectionData)
    }

    private func processImage(
        _ ciImage: CIImage,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) throws -> CIImage {
        var processedImage = ciImage

        let filter = configuration.filter

        switch filter.category {
        case .sizes:
            let faceData = detectionData?.faceTrackingResult
            processedImage = try applySizeFilter(
                processedImage,
                configuration: configuration,
                faceData: faceData
            )
        case .hair:
            let hairData = detectionData?.hairSegmentationResult
            processedImage = try applyHairFilter(
                processedImage,
                configuration: configuration,
                hairData: hairData
            )
        }
        
        return processedImage
    }
    
    private func applySizeFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        faceData: FaceTrackingResult?
    ) throws -> CIImage {
        guard
            let faceData = faceData,
            let primaryFace = faceData.primaryFace,
            let landmarks = primaryFace.landmarks
        else {
            return image
        }
        
        switch configuration.filter {
        case .headSize:
            return try applyHeadPerspectiveFilter(
                image,
                configuration: configuration,
                face: primaryFace,
                landmarks: landmarks,
                imageSize: faceData.imageSize
            )
        default:
            return image
        }
    }
    
    private func applyHeadPerspectiveFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        face: FaceData,
        landmarks: FaceLandmarks,
        imageSize: CGSize
    ) throws -> CIImage {
        let headSizeFilter = HeadSizeFilter()

        let eyeCenter = calculateEyeCenter(
            landmarks: landmarks,
            boundingBox: face.boundingBox,
            imageSize: imageSize
        )
        let (radiusA, radiusB) = calculateFaceRadiuses(
            landmarks: landmarks,
            boundingBox: face.boundingBox,
            imageSize: imageSize,
            center: eyeCenter
        )
        let headAngle = calculateHeadAngle(
            landmarks: landmarks,
            boundingBox: face.boundingBox,
            imageSize: imageSize
        )

        headSizeFilter.inputImage = image
        headSizeFilter.inputCenter = eyeCenter.asCIVector
        headSizeFilter.inputRadiusA = radiusA * 1.36
        headSizeFilter.inputRadiusB = radiusB * 1.37
        headSizeFilter.inputValue = 0.11 * CGFloat(configuration.intensity)
        headSizeFilter.inputHeadAngle = headAngle
        
        return headSizeFilter.outputImage ?? image
    }
    
    // MARK: - Helper Methods for Eye Calculations
    
    private func calculateEyeCenters(
        landmarks: FaceLandmarks,
        boundingBox: NormalizedRect,
        imageSize: CGSize
    ) -> (CGPoint, CGPoint) {
        let leftEyePoints = transformLandmarks(landmarks.leftEye, boundingBox: boundingBox, imageSize: imageSize)
        let rightEyePoints = transformLandmarks(landmarks.rightEye, boundingBox: boundingBox, imageSize: imageSize)
        
        let leftEyeCenter = leftEyePoints.center
        let rightEyeCenter = rightEyePoints.center
        
        return (leftEyeCenter, rightEyeCenter)
    }
    
    private func calculateEyeRadiuses(
        landmarks: FaceLandmarks,
        boundingBox: NormalizedRect,
        imageSize: CGSize
    ) -> (CGFloat, CGFloat) {
        let leftEyePoints = transformLandmarks(landmarks.leftEye, boundingBox: boundingBox, imageSize: imageSize)
        let rightEyePoints = transformLandmarks(landmarks.rightEye, boundingBox: boundingBox, imageSize: imageSize)

        let leftEyeBounds = leftEyePoints.boundingRect
        let rightEyeBounds = rightEyePoints.boundingRect

        let radiusA = max((leftEyeBounds.width + rightEyeBounds.width) / 4, 10)
        let radiusB = max((leftEyeBounds.height + rightEyeBounds.height) / 4, 10)
        
        return (radiusA, radiusB)
    }
    
    // MARK: - Helper Methods for Face Calculations
    
    private func calculateFaceCenter(
        landmarks: FaceLandmarks,
        boundingBox: NormalizedRect,
        imageSize: CGSize
    ) -> CGPoint {
        let leftEye = transformLandmarks(landmarks.leftEye, boundingBox: boundingBox, imageSize: imageSize).center
        let rightEye = transformLandmarks(landmarks.rightEye, boundingBox: boundingBox, imageSize: imageSize).center
        let mouthCenter = transformLandmarks(landmarks.outerLips, boundingBox: boundingBox, imageSize: imageSize).center
        
        let eyeAverage = [leftEye, rightEye].center
        return [eyeAverage, mouthCenter].center
    }
    
    private func calculateEyeCenter(
        landmarks: FaceLandmarks,
        boundingBox: NormalizedRect,
        imageSize: CGSize
    ) -> CGPoint {
        let leftEye = transformLandmarks(landmarks.leftEye, boundingBox: boundingBox, imageSize: imageSize).center
        let rightEye = transformLandmarks(landmarks.rightEye, boundingBox: boundingBox, imageSize: imageSize).center
        return [leftEye, rightEye].center
    }
    
    private func calculateFaceRadiuses(
        landmarks: FaceLandmarks,
        boundingBox: NormalizedRect,
        imageSize: CGSize,
        center: CGPoint
    ) -> (CGFloat, CGFloat) {
        let faceContour = transformLandmarks(landmarks.faceContour, boundingBox: boundingBox, imageSize: imageSize)
        
        guard !faceContour.isEmpty else {
            return (1.0, 1.0)
        }

        // Horizontal radius is the distance from the center to the extreme points of the facial contour.
        let radiusA = max(
            faceContour.first?.distance(center) ?? 1.0,
            faceContour.last?.distance(center) ?? 1.0
        )
        
        // The lowest point of the facial contour for the vertical radius
        let midIndex = faceContour.count / 2
        // Vertical radius is the distance from the center to the midpoint of the facial contour.
        let radiusB = center.distance(faceContour[safe: midIndex] ?? center)

        return (max(radiusA, 1.0), max(radiusB, 1.0))
    }

    private func calculateHeadAngle(
        landmarks: FaceLandmarks,
        boundingBox: NormalizedRect,
        imageSize: CGSize
    ) -> CGFloat {
        let mouthPoints = transformLandmarks(landmarks.outerLips, boundingBox: boundingBox, imageSize: imageSize)
        guard mouthPoints.count > 2 else { return 0 }

        let leftMouthCorner = mouthPoints.last ?? CGPoint.zero
        let rightMouthCorner = mouthPoints[mouthPoints.count / 2]

        // The angle of the line between the corners of the mouth
        // A positive angle is a clockwise rotation.
        // Negative angle - counterclockwise rotation
        let dx = Double(rightMouthCorner.x - leftMouthCorner.x)
        let dy = Double(rightMouthCorner.y - leftMouthCorner.y)
        var angle = atan2(dy, dx)

        // Normalizing an angle to a range [-π/2, π/2]
        if angle > .pi/2 { angle -= .pi }
        if angle < -.pi/2 { angle += .pi }

        return angle
    }

    private func transformLandmarks(
        _ landmarks: FaceObservation.Landmarks2D.Region,
        boundingBox: NormalizedRect,
        imageSize: CGSize
    ) -> [CGPoint] {
        return landmarks.pointsInImageCoordinates(imageSize, origin: .lowerLeft)
//        return landmarks.points.map { landmark in
//            landmark.toImageCoordinates(from: boundingBox, imageSize: imageSize, origin: .lowerLeft)
//        }
    }
    
    private func transformLandmarkPoint(
        _ point: CGPoint,
        boundingBox: CGRect,
        imageSize: CGSize
    ) -> CGPoint {
        // Converting relative coordinates to absolute ones
        let x = boundingBox.minX + boundingBox.width * point.x
        let y = boundingBox.minY + boundingBox.height * point.y
        
        // Enlarge to image size
        return CGPoint(
            x: x * imageSize.width,
            y: y * imageSize.height
        )
    }
    
    private func transformBoundingBox(_ boundingBox: CGRect, imageSize: CGSize) -> CGRect {
        return CGRect(
            x: boundingBox.minX * imageSize.width,
            y: boundingBox.minY * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }
    
    private func applyHairFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult?
    ) throws -> CIImage {
        guard let hairData else {
            return image
        }

        let filter = configuration.filter

        switch filter {
        case .hue:
            return try applyHairHueFilter(image, configuration: configuration, hairData: hairData)
        case .colorTone:
            return try applyHairColorToneFilter(image, configuration: configuration, hairData: hairData)
        case .highlights:
            return try applyHairHighlightsFilter(image, configuration: configuration, hairData: hairData)
        case .hairColorBlack, .hairColorDarkBrown, .hairColorBrown, .hairColorLightBrown,
             .hairColorBlonde, .hairColorPlatinumBlonde, .hairColorRed, .hairColorAuburn,
             .hairColorCopper, .hairColorBurgundy:
            return try applyHairColorFilter(image, configuration: configuration, hairData: hairData)
        case .warmth:
            return try applyHairWarmthFilter(image, configuration: configuration, hairData: hairData)
        case .coolness:
            return try applyHairCoolnessFilter(image, configuration: configuration, hairData: hairData)
        case .balance:
            return try applyHairBalanceFilter(image, configuration: configuration, hairData: hairData)
        case .magentaGreen:
            return try applyHairMagentaGreenFilter(image, configuration: configuration, hairData: hairData)
        case .tintBalance:
            return try applyHairTintBalanceFilter(image, configuration: configuration, hairData: hairData)
        case .colorCast:
            return try applyHairColorCastFilter(image, configuration: configuration, hairData: hairData)
        case .vibrance:
            return try applyHairVibranceFilter(image, configuration: configuration, hairData: hairData)
        case .intensity:
            return try applyHairIntensityFilter(image, configuration: configuration, hairData: hairData)
        case .richness:
            return try applyHairRichnessFilter(image, configuration: configuration, hairData: hairData)
        default:
            return image
        }
    }
    
    // MARK: - Hair Color Filters
    
    private func applyHairColorFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let hairColorFilter = HairColorFilter()

        let filter = configuration.filter

        // Map filter type to HairColorFilter.HairColor
        let hairColor: HairColorFilter.HairColor
        switch filter {
        case .hairColorBlack:
            hairColor = .black
        case .hairColorDarkBrown:
            hairColor = .darkBrown
        case .hairColorBrown:
            hairColor = .brown
        case .hairColorLightBrown:
            hairColor = .lightBrown
        case .hairColorBlonde:
            hairColor = .blonde
        case .hairColorPlatinumBlonde:
            hairColor = .platinumBlonde
        case .hairColorRed:
            hairColor = .red
        case .hairColorAuburn:
            hairColor = .auburn
        case .hairColorCopper:
            hairColor = .copper
        case .hairColorBurgundy:
            hairColor = .burgundy
        default:
            hairColor = .brown // fallback
        }

        let intensity: Float

        switch filter {
        case .hairColorBlonde:
            intensity = configuration.intensity * 0.25
        default:
            intensity = configuration.intensity * 0.3
        }

        let colorValues = hairColor.rgbValues
        hairColorFilter.inputImage = image
        hairColorFilter.inputTargetColor = CIVector(x: colorValues.red, y: colorValues.green, z: colorValues.blue)
        hairColorFilter.inputValue = CGFloat(abs(intensity))

        guard let colorFilteredImage = hairColorFilter.outputImage else { return image }

        return applyHairMask(colorFilteredImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairHueFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let hueAdjustFilter = CIFilter(name: "CIHueAdjust")!
        hueAdjustFilter.setValue(image, forKey: kCIInputImageKey)
        hueAdjustFilter.setValue(CGFloat(configuration.intensity) * .pi, forKey: kCIInputAngleKey) // Convert to radians
        
        guard let adjustedImage = hueAdjustFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairColorToneFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let temperatureFilter = CIFilter(name: "CITemperatureAndTint")!
        temperatureFilter.setValue(image, forKey: kCIInputImageKey)

        let baseTemperature: CGFloat = 6500
        let temperatureAdjustment = CGFloat(configuration.intensity) * 2000
        let tintAdjustment = CGFloat(configuration.intensity) * 150
        
        let inputNeutral = CIVector(x: baseTemperature, y: 0)
        let targetNeutral = CIVector(x: baseTemperature + temperatureAdjustment, y: tintAdjustment)
        
        temperatureFilter.setValue(inputNeutral, forKey: "inputNeutral")
        temperatureFilter.setValue(targetNeutral, forKey: "inputTargetNeutral")
        
        guard let adjustedImage = temperatureFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairHighlightsFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let highlightFilter = CIFilter(name: "CIHighlightShadowAdjust")!
        highlightFilter.setValue(image, forKey: kCIInputImageKey)
        highlightFilter.setValue(1.0 + CGFloat(configuration.intensity) * 0.5, forKey: "inputHighlightAmount")
        highlightFilter.setValue(0.0, forKey: "inputShadowAmount")
        highlightFilter.setValue(abs(CGFloat(configuration.intensity)) * 5.0 + 1.0, forKey: "inputRadius") // Radius based on intensity
        
        guard let adjustedImage = highlightFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    // MARK: - Hair Temperature Filters
    
    private func applyHairWarmthFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let temperatureFilter = CIFilter(name: "CITemperatureAndTint")!
        temperatureFilter.setValue(image, forKey: kCIInputImageKey)

        let baseTemperature: CGFloat = 6500
        let temperatureAdjustment = CGFloat(configuration.intensity) * -1500
        
        let inputNeutral = CIVector(x: baseTemperature, y: 0)
        let targetNeutral = CIVector(x: baseTemperature + temperatureAdjustment, y: 0)
        
        temperatureFilter.setValue(inputNeutral, forKey: "inputNeutral")
        temperatureFilter.setValue(targetNeutral, forKey: "inputTargetNeutral")
        
        guard let adjustedImage = temperatureFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairCoolnessFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let temperatureFilter = CIFilter(name: "CITemperatureAndTint")!
        temperatureFilter.setValue(image, forKey: kCIInputImageKey)

        let baseTemperature: CGFloat = 6500
        let temperatureAdjustment = CGFloat(configuration.intensity) * 1500
        
        let inputNeutral = CIVector(x: baseTemperature, y: 0)
        let targetNeutral = CIVector(x: baseTemperature + temperatureAdjustment, y: 0)
        
        temperatureFilter.setValue(inputNeutral, forKey: "inputNeutral")
        temperatureFilter.setValue(targetNeutral, forKey: "inputTargetNeutral")
        
        guard let adjustedImage = temperatureFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairBalanceFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let whitePointFilter = CIFilter(name: "CIWhitePointAdjust")!
        whitePointFilter.setValue(image, forKey: kCIInputImageKey)
        let adjustment = CIColor(
            red: 1.0 + CGFloat(configuration.intensity) * 0.1,
            green: 1.0,
            blue: 1.0 - CGFloat(configuration.intensity) * 0.1
        )
        whitePointFilter.setValue(adjustment, forKey: "inputColor")
        
        guard let adjustedImage = whitePointFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    // MARK: - Hair Tint Filters
    
    private func applyHairMagentaGreenFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let temperatureFilter = CIFilter(name: "CITemperatureAndTint")!
        temperatureFilter.setValue(image, forKey: kCIInputImageKey)

        let baseTemperature: CGFloat = 6500
        let tintAdjustment = CGFloat(configuration.intensity) * 150
        
        let inputNeutral = CIVector(x: baseTemperature, y: 0)
        let targetNeutral = CIVector(x: baseTemperature, y: tintAdjustment)
        
        temperatureFilter.setValue(inputNeutral, forKey: "inputNeutral")
        temperatureFilter.setValue(targetNeutral, forKey: "inputTargetNeutral")
        
        guard let adjustedImage = temperatureFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairTintBalanceFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
        colorMatrixFilter.setValue(image, forKey: kCIInputImageKey)
        
        let tintIntensity = CGFloat(configuration.intensity) * 0.1
        colorMatrixFilter.setValue(CIVector(x: 1.0 + tintIntensity, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 1.0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 1.0 - tintIntensity, w: 0), forKey: "inputBVector")
        
        guard let adjustedImage = colorMatrixFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairColorCastFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(image, forKey: kCIInputImageKey)
        colorFilter.setValue(1.0 + CGFloat(configuration.intensity) * 0.2, forKey: kCIInputSaturationKey)
        
        guard let adjustedImage = colorFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    // MARK: - Hair Saturation Filters
    
    private func applyHairVibranceFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let vibranceFilter = CIFilter(name: "CIVibrance")!
        vibranceFilter.setValue(image, forKey: kCIInputImageKey)
        vibranceFilter.setValue(CGFloat(configuration.intensity) * 1.0, forKey: "inputAmount")
        
        guard let adjustedImage = vibranceFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairIntensityFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        let saturationFilter = CIFilter(name: "CIColorControls")!
        saturationFilter.setValue(image, forKey: kCIInputImageKey)
        saturationFilter.setValue(1.0 + CGFloat(configuration.intensity) * 0.5, forKey: kCIInputSaturationKey)
        
        guard let adjustedImage = saturationFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    private func applyHairRichnessFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult
    ) throws -> CIImage {
        // Combine saturation and contrast for richness effect
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(image, forKey: kCIInputImageKey)
        colorFilter.setValue(1.0 + CGFloat(configuration.intensity) * 0.3, forKey: kCIInputSaturationKey)
        colorFilter.setValue(1.0 + CGFloat(configuration.intensity) * 0.1, forKey: kCIInputContrastKey)
        
        guard let adjustedImage = colorFilter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairData.hairMask)
    }
    
    // MARK: - Hair Mask Application Helper
    
    private func applyHairMask(_ adjustedImage: CIImage, originalImage: CIImage, hairMask: CIImage) -> CIImage {
        let blurredMask = hairMask

        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(adjustedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(originalImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(blurredMask, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? originalImage
    }
}
