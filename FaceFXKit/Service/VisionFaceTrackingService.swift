//
//  VisionFaceTrackingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Vision
@preconcurrency import CoreImage

protocol VisionFaceTrackingService {
    func detectFaces(in ciImage: CIImage) async throws -> FaceTrackingResult
}

actor DefaultVisionFaceTrackingService: VisionFaceTrackingService {
    enum FaceTrackingError: LocalizedError {
        case noFacesDetected

        var errorDescription: String? { "No faces detected in the photo" }
    }

    private let faceRectangleRequest = DetectFaceRectanglesRequest(.revision4)

    func detectFaces(in ciImage: CIImage) async throws -> FaceTrackingResult {
        let faces = try await faceRectangleRequest.perform(on: ciImage)
        guard !faces.isEmpty else { throw FaceTrackingError.noFacesDetected }

        var landmarksRequest = DetectFaceLandmarksRequest(.revision4)
        landmarksRequest.inputFaceObservations = faces
        let observations = try await landmarksRequest.perform(on: ciImage)

        return FaceTrackingResult(faces: observations.map(FaceData.init), imageSize: ciImage.extent.size)
    }
}
