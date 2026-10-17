//
//  DetectionData.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 25/07/2025.
//

import Foundation

enum DetectionData {
    case faceLandmarks(FaceTrackingResult)
    case hairSegmentation(HairSegmentationResult)

    var categories: [FilterCategory] {
        switch self {
        case .faceLandmarks: [.sizes]
        case .hairSegmentation: [.hair]
        }
    }

    var faceTrackingResult: FaceTrackingResult? {
        if case .faceLandmarks(let result) = self { result } else { nil }
    }

    var hairSegmentationResult: HairSegmentationResult? {
        if case .hairSegmentation(let result) = self { result } else { nil }
    }
}
