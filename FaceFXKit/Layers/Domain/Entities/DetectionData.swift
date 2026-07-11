//
//  DetectionData.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 25/07/2025.
//

import Foundation
import UIKit

enum DetectionData {
    case faceLandmarks(FaceTrackingResult)
    case hairSegmentation(HairSegmentationResult)

    var categories: [FilterCategory] {
        switch self {
        case .faceLandmarks:
            return [.sizes]
        case .hairSegmentation:
            return [.hair]
        }
    }

    var faceTrackingResult: FaceTrackingResult? {
        switch self {
        case .faceLandmarks(let result):
            return result
        case .hairSegmentation:
            return nil
        }
    }

    var hairSegmentationResult: HairSegmentationResult? {
        switch self {
        case .faceLandmarks:
            return nil
        case .hairSegmentation(let result):
            return result
        }
    }
}
