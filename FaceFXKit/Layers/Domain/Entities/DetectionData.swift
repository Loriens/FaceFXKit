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
    case combined(faces: FaceTrackingResult, hair: HairSegmentationResult)
    
    var categories: [FilterCategory] {
        switch self {
        case .faceLandmarks:
            return [.sizes]
        case .hairSegmentation:
            return [.hair]
        case .combined:
            return [.sizes, .hair]
        }
    }
    
    var faceTrackingResult: FaceTrackingResult? {
        switch self {
        case .faceLandmarks(let result):
            return result
        case .hairSegmentation:
            return nil
        case .combined(let faces, _):
            return faces
        }
    }
    
    var hairSegmentationResult: HairSegmentationResult? {
        switch self {
        case .faceLandmarks:
            return nil
        case .hairSegmentation(let result):
            return result
        case .combined(_, let hair):
            return hair
        }
    }
}
