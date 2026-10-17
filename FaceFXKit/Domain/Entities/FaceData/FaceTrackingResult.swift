//
//  FaceTrackingResult.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 25/07/2025.
//

import Foundation

struct FaceTrackingResult: Sendable {
    let faces: [FaceData]
    let imageSize: CGSize
    let processedAt: Date

    init(faces: [FaceData], imageSize: CGSize) {
        self.faces = faces
        self.imageSize = imageSize
        self.processedAt = Date()
    }

    var primaryFace: FaceData? {
        faces.first
    }
}
