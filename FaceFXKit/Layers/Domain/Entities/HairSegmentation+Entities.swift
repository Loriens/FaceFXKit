//
//  HairSegmentation+Entities.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 29/07/2025.
//

import Foundation
import CoreImage
import UIKit

struct HairSegmentationResult: @unchecked Sendable {
    let imageSize: CGSize
    let hairMask: CIImage
    let originalHairMask: CIImage
    let processedAt: Date
}

// MARK: - Error Types

enum HairSegmentationError: Error {
    case invalidImage
    case modelLoadingFailed
    case predictionFailed
    case insufficientHairDetected
    case processingFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Invalid or corrupted image provided"
        case .modelLoadingFailed:
            return "Failed to load hair segmentation model"
        case .predictionFailed:
            return "Hair segmentation prediction failed"
        case .insufficientHairDetected:
            return "Not enough hair detected in the image"
        case .processingFailed(let message):
            return "Hair segmentation processing failed: \(message)"
        }
    }
}
