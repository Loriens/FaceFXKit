//
//  VisionFaceTrackingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import Vision
@preconcurrency import CoreImage

protocol VisionFaceTrackingService {
    func detectFaces(in ciImage: CIImage) async throws -> FaceTrackingResult
}

actor DefaultVisionFaceTrackingService: VisionFaceTrackingService {
    enum FaceTrackingError: Error {
        case invalidImage
        case noFacesDetected
        case visionProcessingFailed
    }

    private let faceRectangleRequest = DetectFaceRectanglesRequest(.revision3)

    func detectFaces(in ciImage: CIImage) async throws -> FaceTrackingResult {
        let faces = try await faceRectangleRequest.perform(on: ciImage)

        guard !faces.isEmpty else {
            throw FaceTrackingError.noFacesDetected
        }

        // Local request: keeping this as actor state would race across
        // reentrant calls between the assignment and `perform`.
        var faceLandmarksRequest = DetectFaceLandmarksRequest(.revision3)
        faceLandmarksRequest.inputFaceObservations = faces

        let landmarksResults = try await faceLandmarksRequest.perform(on: ciImage)

        let result = FaceTrackingResult(
            faces: landmarksResults.map { FaceData(from: $0) },
            imageSize: ciImage.extent.size
        )

        return result
    }
}
