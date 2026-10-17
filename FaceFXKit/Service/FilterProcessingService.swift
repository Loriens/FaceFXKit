//
//  FilterProcessingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import CoreImage
import Vision

protocol FilterProcessingService {
    func applyFilters(
        to image: CIImage,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) throws -> CIImage
}

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
            applySizeFilter(image, configuration: configuration, faceData: detectionData?.faceTrackingResult)
        case .hair:
            applyHairFilter(image, configuration: configuration, hairData: detectionData?.hairSegmentationResult)
        }
    }

    // MARK: - Size Filters

    private func applySizeFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        faceData: FaceTrackingResult?
    ) -> CIImage {
        guard
            configuration.filter == .headSize,
            let faceData,
            let landmarks = faceData.primaryFace?.landmarks
        else { return image }

        let imageSize = faceData.imageSize
        let eyeCenter = eyeCenter(landmarks: landmarks, imageSize: imageSize)
        let (radiusA, radiusB) = faceRadii(landmarks: landmarks, imageSize: imageSize, center: eyeCenter)

        let filter = HeadSizeFilter()
        filter.inputImage = image
        filter.inputCenter = eyeCenter.asCIVector
        filter.inputRadiusA = radiusA * HeadSizeTuning.horizontalRadiusScale
        filter.inputRadiusB = radiusB * HeadSizeTuning.verticalRadiusScale
        filter.inputValue = HeadSizeTuning.intensityScale * CGFloat(configuration.intensity)
        filter.inputHeadAngle = headAngle(landmarks: landmarks, imageSize: imageSize)

        return filter.outputImage ?? image
    }

    // MARK: - Face Geometry

    private func eyeCenter(landmarks: FaceLandmarks, imageSize: CGSize) -> CGPoint {
        let leftEye = points(of: landmarks.leftEye, in: imageSize).center
        let rightEye = points(of: landmarks.rightEye, in: imageSize).center
        return [leftEye, rightEye].center
    }

    private func faceRadii(
        landmarks: FaceLandmarks,
        imageSize: CGSize,
        center: CGPoint
    ) -> (CGFloat, CGFloat) {
        let contour = points(of: landmarks.faceContour, in: imageSize)
        guard let first = contour.first, let last = contour.last else { return (1, 1) }

        // Horizontal radius is the distance from the center to the extreme points of the facial contour.
        let radiusA = max(first.distance(center), last.distance(center))

        // The lowest point of the facial contour for the vertical radius
        // Vertical radius is the distance from the center to the midpoint of the facial contour.
        let radiusB = center.distance(contour[contour.count / 2])

        return (max(radiusA, 1), max(radiusB, 1))
    }

    private func headAngle(landmarks: FaceLandmarks, imageSize: CGSize) -> CGFloat {
        let mouth = points(of: landmarks.outerLips, in: imageSize)
        guard mouth.count > 2, let leftCorner = mouth.last else { return 0 }

        let rightCorner = mouth[mouth.count / 2]

        // The angle of the line between the corners of the mouth
        // A positive angle is a clockwise rotation.
        // Negative angle - counterclockwise rotation
        var angle = atan2(rightCorner.y - leftCorner.y, rightCorner.x - leftCorner.x)

        // Normalizing an angle to a range [-π/2, π/2]
        if angle > .pi / 2 { angle -= .pi }
        if angle < -.pi / 2 { angle += .pi }

        return angle
    }

    private func points(of region: FaceObservation.Landmarks2D.Region, in imageSize: CGSize) -> [CGPoint] {
        region.pointsInImageCoordinates(imageSize, origin: .lowerLeft)
    }

    // MARK: - Hair Filters

    private func applyHairFilter(
        _ image: CIImage,
        configuration: FilterConfiguration,
        hairData: HairSegmentationResult?
    ) -> CIImage {
        guard let hairData else { return image }

        let mask = hairData.hairMask
        let intensity = CGFloat(configuration.intensity)

        if let hairColor = HairColorFilter.HairColor(filterType: configuration.filter) {
            return applyHairColor(hairColor, to: image, intensity: intensity, mask: mask)
        }

        switch configuration.filter {
        case .hue:
            return applyMasked("CIHueAdjust", to: image, mask: mask) {
                $0.setValue(intensity * .pi, forKey: kCIInputAngleKey) // Convert to radians
            }

        case .colorTone:
            return applyTemperatureAndTint(to: image, mask: mask, temperature: intensity * 2000, tint: intensity * 150)

        case .highlights:
            return applyMasked("CIHighlightShadowAdjust", to: image, mask: mask) {
                $0.setValue(1 + intensity * 0.5, forKey: "inputHighlightAmount")
                $0.setValue(0, forKey: "inputShadowAmount")
                $0.setValue(abs(intensity) * 5 + 1, forKey: "inputRadius") // Radius based on intensity
            }

        case .warmth:
            return applyTemperatureAndTint(to: image, mask: mask, temperature: intensity * -1500)

        case .coolness:
            return applyTemperatureAndTint(to: image, mask: mask, temperature: intensity * 1500)

        case .balance:
            return applyMasked("CIWhitePointAdjust", to: image, mask: mask) {
                let color = CIColor(red: 1 + intensity * 0.1, green: 1, blue: 1 - intensity * 0.1)
                $0.setValue(color, forKey: "inputColor")
            }

        case .magentaGreen:
            return applyTemperatureAndTint(to: image, mask: mask, tint: intensity * 150)

        case .tintBalance:
            return applyMasked("CIColorMatrix", to: image, mask: mask) {
                let tint = intensity * 0.1
                $0.setValue(CIVector(x: 1 + tint, y: 0, z: 0, w: 0), forKey: "inputRVector")
                $0.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
                $0.setValue(CIVector(x: 0, y: 0, z: 1 - tint, w: 0), forKey: "inputBVector")
            }

        case .colorCast:
            // "Color cast" is a gentle saturation shift.
            return applyMasked("CIColorControls", to: image, mask: mask) {
                $0.setValue(1 + intensity * 0.2, forKey: kCIInputSaturationKey)
            }

        case .vibrance:
            return applyMasked("CIVibrance", to: image, mask: mask) {
                $0.setValue(intensity, forKey: "inputAmount")
            }

        case .intensity:
            return applyMasked("CIColorControls", to: image, mask: mask) {
                $0.setValue(1 + intensity * 0.5, forKey: kCIInputSaturationKey)
            }

        case .richness:
            // Combine saturation and contrast for richness effect
            return applyMasked("CIColorControls", to: image, mask: mask) {
                $0.setValue(1 + intensity * 0.3, forKey: kCIInputSaturationKey)
                $0.setValue(1 + intensity * 0.1, forKey: kCIInputContrastKey)
            }

        default:
            return image
        }
    }

    private func applyHairColor(
        _ hairColor: HairColorFilter.HairColor,
        to image: CIImage,
        intensity: CGFloat,
        mask: CIImage
    ) -> CIImage {
        // Blonde needs a lighter touch than the other colors.
        let scale: CGFloat = hairColor == .blonde ? 0.25 : 0.3
        let rgb = hairColor.rgbValues

        let filter = HairColorFilter()
        filter.inputImage = image
        filter.inputTargetColor = CIVector(x: rgb.red, y: rgb.green, z: rgb.blue)
        filter.inputValue = abs(intensity * scale)

        guard let colored = filter.outputImage else { return image }
        return blend(colored, over: image, mask: mask)
    }

    // MARK: - Shared Helpers

    /// Runs a named `CIFilter` over the image, then blends the result back onto
    /// the original through the hair mask — the shape every hair filter shares.
    private func applyMasked(
        _ filterName: String,
        to image: CIImage,
        mask: CIImage,
        configure: (CIFilter) -> Void
    ) -> CIImage {
        let filter = CIFilter(name: filterName)!
        filter.setValue(image, forKey: kCIInputImageKey)
        configure(filter)

        guard let adjusted = filter.outputImage else { return image }
        return blend(adjusted, over: image, mask: mask)
    }

    private func applyTemperatureAndTint(
        to image: CIImage,
        mask: CIImage,
        temperature: CGFloat = 0,
        tint: CGFloat = 0
    ) -> CIImage {
        applyMasked("CITemperatureAndTint", to: image, mask: mask) {
            $0.setValue(CIVector(x: Self.neutralTemperature, y: 0), forKey: "inputNeutral")
            $0.setValue(CIVector(x: Self.neutralTemperature + temperature, y: tint), forKey: "inputTargetNeutral")
        }
    }

    private func blend(_ adjusted: CIImage, over original: CIImage, mask: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIBlendWithMask")!
        filter.setValue(adjusted, forKey: kCIInputImageKey)
        filter.setValue(original, forKey: kCIInputBackgroundImageKey)
        filter.setValue(mask, forKey: kCIInputMaskImageKey)

        return filter.outputImage ?? original
    }
}
