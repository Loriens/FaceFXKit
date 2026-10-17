//
//  HairSegmentation+Entities.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 29/07/2025.
//

import Foundation
import CoreImage

struct HairSegmentationResult: @unchecked Sendable {
    let imageSize: CGSize
    let hairMask: CIImage
    let originalHairMask: CIImage
    let processedAt: Date
}

// MARK: - Error Types

enum HairSegmentationError: LocalizedError {
    case modelLoadingFailed
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelLoadingFailed: "Failed to load hair segmentation model"
        case .processingFailed(let message): "Hair segmentation processing failed: \(message)"
        }
    }
}
