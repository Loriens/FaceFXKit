//
//  FilterProcessingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import CoreImage
import Vision

protocol FilterProcessingService {
    func applyFilters(
        to image: CIImage,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) throws -> CIImage
}

/// Builds Core Image filter graphs for every `FilterType`. Stateless, so it is
/// safe to use from any isolation.
final class DefaultFilterProcessingService: FilterProcessingService, Sendable {

    /// Empirically tuned multipliers for the head-resize warp.
    private enum HeadSizeTuning {
        /// Widens the warp ellipse horizontally beyond the detected face radius.
        static let horizontalRadiusScale: CGFloat = 1.36
        /// Widens the warp ellipse vertically beyond the detected face radius.
        static let verticalRadiusScale: CGFloat = 1.37
        /// Converts slider intensity (-1...1) into warp strength.
        static let intensityScale: CGFloat = 0.11
    }

    /// Neutral daylight white point for `CITemperatureAndTint`, in kelvin.
    private static let neutralTemperature: CGFloat = 6500

    func applyFilters(
        to image: CIImage,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) throws -> CIImage {
        switch configuration.filter.category {
        case .sizes:
            return applySizeFilter(
                image,
                configuration: configuration,
                faceData: detectionData?.faceTrackingResult
            )
        case .hair:
            return applyHairFilter(
                image,
                configuration: configuration,
                hairData: detectionData?.hairSegmentationResult
            )
        }
    }

    // MARK: - Size Filters

    private func applySizeFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        faceData: FaceTrackingResult?
    ) -> CIImage {
        guard
            let faceData,
            let primaryFace = faceData.primaryFace,
            let landmarks = primaryFace.landmarks
        else {
            return image
        }

        switch configuration.filter {
        case .headSize:
            return applyHeadSizeFilter(
                image,
                configuration: configuration,
                landmarks: landmarks,
                imageSize: faceData.imageSize
            )
        default:
            return image
        }
    }

    private func applyHeadSizeFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        landmarks: FaceLandmarks,
        imageSize: CGSize
    ) -> CIImage {
        let headSizeFilter = HeadSizeFilter()

        let eyeCenter = calculateEyeCenter(landmarks: landmarks, imageSize: imageSize)
        let (radiusA, radiusB) = calculateFaceRadiuses(
            landmarks: landmarks,
            imageSize: imageSize,
            center: eyeCenter
        )
        let headAngle = calculateHeadAngle(landmarks: landmarks, imageSize: imageSize)

        headSizeFilter.inputImage = image
        headSizeFilter.inputCenter = eyeCenter.asCIVector
        headSizeFilter.inputRadiusA = radiusA * HeadSizeTuning.horizontalRadiusScale
        headSizeFilter.inputRadiusB = radiusB * HeadSizeTuning.verticalRadiusScale
        headSizeFilter.inputValue = HeadSizeTuning.intensityScale * CGFloat(configuration.intensity)
        headSizeFilter.inputHeadAngle = headAngle

        return headSizeFilter.outputImage ?? image
    }

    // MARK: - Face Geometry

    private func calculateEyeCenter(landmarks: FaceLandmarks, imageSize: CGSize) -> CGPoint {
        let leftEye = transformLandmarks(landmarks.leftEye, imageSize: imageSize).center
        let rightEye = transformLandmarks(landmarks.rightEye, imageSize: imageSize).center
        return [leftEye, rightEye].center
    }

    private func calculateFaceRadiuses(
        landmarks: FaceLandmarks,
        imageSize: CGSize,
        center: CGPoint
    ) -> (CGFloat, CGFloat) {
        let faceContour = transformLandmarks(landmarks.faceContour, imageSize: imageSize)

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

    private func calculateHeadAngle(landmarks: FaceLandmarks, imageSize: CGSize) -> CGFloat {
        let mouthPoints = transformLandmarks(landmarks.outerLips, imageSize: imageSize)
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
        imageSize: CGSize
    ) -> [CGPoint] {
        return landmarks.pointsInImageCoordinates(imageSize, origin: .lowerLeft)
    }

    // MARK: - Hair Filters

    private func applyHairFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult?
    ) -> CIImage {
        guard let hairData else {
            return image
        }

        let filter = configuration.filter
        let intensity = CGFloat(configuration.intensity)
        let hairMask = hairData.hairMask

        if let hairColor = HairColorFilter.HairColor(filterType: filter) {
            return applyHairColorFilter(
                image,
                hairColor: hairColor,
                filterType: filter,
                intensity: configuration.intensity,
                hairMask: hairMask
            )
        }

        switch filter {
        case .hue:
            return applyMaskedFilter("CIHueAdjust", to: image, hairMask: hairMask) {
                $0.setValue(intensity * .pi, forKey: kCIInputAngleKey) // Convert to radians
            }
        case .colorTone:
            return applyTemperatureAndTint(
                to: image,
                hairMask: hairMask,
                temperatureOffset: intensity * 2000,
                tintOffset: intensity * 150
            )
        case .highlights:
            return applyMaskedFilter("CIHighlightShadowAdjust", to: image, hairMask: hairMask) {
                $0.setValue(1.0 + intensity * 0.5, forKey: "inputHighlightAmount")
                $0.setValue(0.0, forKey: "inputShadowAmount")
                $0.setValue(abs(intensity) * 5.0 + 1.0, forKey: "inputRadius") // Radius based on intensity
            }
        case .warmth:
            return applyTemperatureAndTint(
                to: image,
                hairMask: hairMask,
                temperatureOffset: intensity * -1500,
                tintOffset: 0
            )
        case .coolness:
            return applyTemperatureAndTint(
                to: image,
                hairMask: hairMask,
                temperatureOffset: intensity * 1500,
                tintOffset: 0
            )
        case .balance:
            return applyMaskedFilter("CIWhitePointAdjust", to: image, hairMask: hairMask) {
                let adjustment = CIColor(
                    red: 1.0 + intensity * 0.1,
                    green: 1.0,
                    blue: 1.0 - intensity * 0.1
                )
                $0.setValue(adjustment, forKey: "inputColor")
            }
        case .magentaGreen:
            return applyTemperatureAndTint(
                to: image,
                hairMask: hairMask,
                temperatureOffset: 0,
                tintOffset: intensity * 150
            )
        case .tintBalance:
            return applyMaskedFilter("CIColorMatrix", to: image, hairMask: hairMask) {
                let tintIntensity = intensity * 0.1
                $0.setValue(CIVector(x: 1.0 + tintIntensity, y: 0, z: 0, w: 0), forKey: "inputRVector")
                $0.setValue(CIVector(x: 0, y: 1.0, z: 0, w: 0), forKey: "inputGVector")
                $0.setValue(CIVector(x: 0, y: 0, z: 1.0 - tintIntensity, w: 0), forKey: "inputBVector")
            }
        case .colorCast:
            // "Color cast" is a gentle saturation shift.
            return applyMaskedFilter("CIColorControls", to: image, hairMask: hairMask) {
                $0.setValue(1.0 + intensity * 0.2, forKey: kCIInputSaturationKey)
            }
        case .vibrance:
            return applyMaskedFilter("CIVibrance", to: image, hairMask: hairMask) {
                $0.setValue(intensity, forKey: "inputAmount")
            }
        case .intensity:
            return applyMaskedFilter("CIColorControls", to: image, hairMask: hairMask) {
                $0.setValue(1.0 + intensity * 0.5, forKey: kCIInputSaturationKey)
            }
        case .richness:
            // Combine saturation and contrast for richness effect
            return applyMaskedFilter("CIColorControls", to: image, hairMask: hairMask) {
                $0.setValue(1.0 + intensity * 0.3, forKey: kCIInputSaturationKey)
                $0.setValue(1.0 + intensity * 0.1, forKey: kCIInputContrastKey)
            }
        default:
            return image
        }
    }

    private func applyHairColorFilter(
        _ image: CIImage,
        hairColor: HairColorFilter.HairColor,
        filterType: FilterType,
        intensity: Float,
        hairMask: CIImage
    ) -> CIImage {
        let hairColorFilter = HairColorFilter()

        // Blonde needs a lighter touch than the other colors.
        let scaledIntensity = filterType == .hairColorBlonde ? intensity * 0.25 : intensity * 0.3

        let colorValues = hairColor.rgbValues
        hairColorFilter.inputImage = image
        hairColorFilter.inputTargetColor = CIVector(x: colorValues.red, y: colorValues.green, z: colorValues.blue)
        hairColorFilter.inputValue = CGFloat(abs(scaledIntensity))

        guard let colorFilteredImage = hairColorFilter.outputImage else { return image }

        return applyHairMask(colorFilteredImage, originalImage: image, hairMask: hairMask)
    }

    // MARK: - Shared Helpers

    /// Runs a named `CIFilter` over the image, then blends the result back onto
    /// the original through the hair mask — the shape every hair filter shares.
    private func applyMaskedFilter(
        _ filterName: String,
        to image: CIImage,
        hairMask: CIImage,
        configure: (CIFilter) -> Void
    ) -> CIImage {
        let filter = CIFilter(name: filterName)!
        filter.setValue(image, forKey: kCIInputImageKey)
        configure(filter)

        guard let adjustedImage = filter.outputImage else { return image }
        return applyHairMask(adjustedImage, originalImage: image, hairMask: hairMask)
    }

    private func applyTemperatureAndTint(
        to image: CIImage,
        hairMask: CIImage,
        temperatureOffset: CGFloat,
        tintOffset: CGFloat
    ) -> CIImage {
        applyMaskedFilter("CITemperatureAndTint", to: image, hairMask: hairMask) { filter in
            filter.setValue(CIVector(x: Self.neutralTemperature, y: 0), forKey: "inputNeutral")
            filter.setValue(
                CIVector(x: Self.neutralTemperature + temperatureOffset, y: tintOffset),
                forKey: "inputTargetNeutral"
            )
        }
    }

    private func applyHairMask(_ adjustedImage: CIImage, originalImage: CIImage, hairMask: CIImage) -> CIImage {
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(adjustedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(originalImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(hairMask, forKey: kCIInputMaskImageKey)

        return blendFilter.outputImage ?? originalImage
    }
}
