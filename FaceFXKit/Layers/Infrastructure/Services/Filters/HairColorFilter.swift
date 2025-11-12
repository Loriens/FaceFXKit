//
//  HairColorFilter.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 30/07/2025.
//

import Foundation
@preconcurrency import CoreImage
import Metal
import UIKit

final class HairColorFilter: CIFilter, @unchecked Sendable {
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputTargetColor: CIVector = CIVector(x: 0.0, y: 0.0, z: 0.0)
    @objc dynamic var inputValue: CGFloat = 1.0

    private static let kernel: CIColorKernel? = {
        guard
            let url = Bundle.main.url(forResource: "default", withExtension: "metallib"),
            let data = try? Data(contentsOf: url),
            let kernel = try? CIColorKernel(functionName: "hairColor", fromMetalLibraryData: data)
        else {
            fatalError("HairColorFilter: Could not load HairColor.metal")
        }
        
        return kernel
    }()
    
    override var outputImage: CIImage? {
        guard let inputImage, let kernel = Self.kernel else {
            print("⚠️ HairColorFilter: Missing required inputs")
            return inputImage
        }
        
        let outputImage = kernel.apply(
            extent: inputImage.extent,
            arguments: [
                inputImage,
                inputTargetColor,
                inputValue
            ]
        )
        
        return outputImage?.cropped(to: inputImage.extent) ?? inputImage
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
            case .black:
                return (0.1, 0.05, 0.05)
            case .darkBrown:
                return (0.2, 0.1, 0.05)
            case .brown:
                return (0.4, 0.25, 0.15)
            case .lightBrown:
                return (0.5, 0.35, 0.2)
            case .blonde:
                return (0.8, 0.7, 0.5)
            case .platinumBlonde:
                return (0.9, 0.9, 0.85)
            case .red:
                return (0.7, 0.2, 0.1)
            case .auburn:
                return (0.5, 0.2, 0.1)
            case .copper:
                return (0.7, 0.35, 0.15)
            case .burgundy:
                return (0.4, 0.1, 0.15)
            }
        }
        
        var displayName: String {
            switch self {
            case .black: return "Black"
            case .darkBrown: return "Dark Brown"
            case .brown: return "Brown"
            case .lightBrown: return "Light Brown"
            case .blonde: return "Blonde"
            case .platinumBlonde: return "Platinum Blonde"
            case .red: return "Red"
            case .auburn: return "Auburn"
            case .copper: return "Copper"
            case .burgundy: return "Burgundy"
            }
        }
    }
}
