//
//  HairColorFilter.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 30/07/2025.
//

@preconcurrency import CoreImage

final class HairColorFilter: CIFilter, @unchecked Sendable {
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputTargetColor = CIVector(x: 0, y: 0, z: 0)
    @objc dynamic var inputValue: CGFloat = 1

    private static let kernel: CIColorKernel = {
        guard
            let url = Bundle.main.url(forResource: "default", withExtension: "metallib"),
            let data = try? Data(contentsOf: url),
            let kernel = try? CIColorKernel(functionName: "hairColor", fromMetalLibraryData: data)
        else {
            fatalError("HairColorFilter: Could not load HairColorFilter.metal")
        }
        return kernel
    }()

    override var outputImage: CIImage? {
        guard let inputImage else { return nil }

        let output = Self.kernel.apply(
            extent: inputImage.extent,
            arguments: [inputImage, inputTargetColor, inputValue]
        )
        return output?.cropped(to: inputImage.extent) ?? inputImage
    }
}

// MARK: - Predefined Hair Colors

extension HairColorFilter {
    enum HairColor {
        case black
        case darkBrown
        case brown
        case lightBrown
        case blonde
        case platinumBlonde
        case red
        case auburn
        case copper
        case burgundy

        var rgbValues: (red: CGFloat, green: CGFloat, blue: CGFloat) {
            switch self {
            case .black:          (0.1, 0.05, 0.05)
            case .darkBrown:      (0.2, 0.1, 0.05)
            case .brown:          (0.4, 0.25, 0.15)
            case .lightBrown:     (0.5, 0.35, 0.2)
            case .blonde:         (0.8, 0.7, 0.5)
            case .platinumBlonde: (0.9, 0.9, 0.85)
            case .red:            (0.7, 0.2, 0.1)
            case .auburn:         (0.5, 0.2, 0.1)
            case .copper:         (0.7, 0.35, 0.15)
            case .burgundy:       (0.4, 0.1, 0.15)
            }
        }

        /// Maps a hair-color filter type to its color; `nil` for every other filter.
        init?(filterType: FilterType) {
            switch filterType {
            case .hairColorBlack:          self = .black
            case .hairColorDarkBrown:      self = .darkBrown
            case .hairColorBrown:          self = .brown
            case .hairColorLightBrown:     self = .lightBrown
            case .hairColorBlonde:         self = .blonde
            case .hairColorPlatinumBlonde: self = .platinumBlonde
            case .hairColorRed:            self = .red
            case .hairColorAuburn:         self = .auburn
            case .hairColorCopper:         self = .copper
            case .hairColorBurgundy:       self = .burgundy
            default:                       return nil
            }
        }
    }
}
