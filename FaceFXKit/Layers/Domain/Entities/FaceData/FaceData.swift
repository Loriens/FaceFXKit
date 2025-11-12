//
//  FaceData.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import Vision
import CoreGraphics

struct FaceData {
    let id: UUID
    let observation: FaceObservation
    let boundingBox: NormalizedRect
    let confidence: Float
    let landmarks: FaceLandmarks?
    let detectedAt: Date
    
    init(from observation: FaceObservation) {
        self.id = UUID()
        self.observation = observation
        self.boundingBox = observation.boundingBox
        self.confidence = observation.confidence
        self.landmarks = observation.landmarks.map { FaceLandmarks(from: $0) }
        self.detectedAt = Date()
    }
}
