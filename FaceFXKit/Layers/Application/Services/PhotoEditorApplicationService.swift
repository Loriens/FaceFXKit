//
//  PhotoEditorApplicationService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import CoreImage

/// Orchestrates photo editing: runs the detection required by a filter's
/// category, applies the filter, and saves results.
///
/// @unchecked Sendable safety invariant: all stored properties are immutable
/// (`let`) references to services that are either actors
/// (`DefaultVisionFaceTrackingService`, `DefaultHairSegmentationService`) or
/// internally thread-safe (see each type's own invariant).
final class PhotoEditorApplicationService: @unchecked Sendable {
    private let filterProcessingService: FilterProcessingService
    private let photoStorageService: PhotoStorageService
    private let faceTrackingService: VisionFaceTrackingService
    private let hairSegmentationService: HairSegmentationService

    init(
        filterProcessingService: FilterProcessingService,
        photoStorageService: PhotoStorageService,
        faceTrackingService: VisionFaceTrackingService,
        hairSegmentationService: HairSegmentationService
    ) {
        self.filterProcessingService = filterProcessingService
        self.photoStorageService = photoStorageService
        self.faceTrackingService = faceTrackingService
        self.hairSegmentationService = hairSegmentationService
    }

    func applyFilters(
        to photo: Photo,
        configuration: FilterConfiguration,
        detectionData: DetectionData? = nil
    ) async throws -> Photo {
        let resolvedDetectionData: DetectionData
        if let detectionData {
            resolvedDetectionData = detectionData
        } else {
            resolvedDetectionData = try await detectData(
                in: photo.originalImage,
                for: configuration.filter.category
            )
        }

        let processedImage = try filterProcessingService.applyFilters(
            to: photo.originalImage,
            with: configuration,
            detectionData: resolvedDetectionData
        )

        var updatedPhoto = photo
        updatedPhoto.updateProcessedImage(processedImage)
        return updatedPhoto
    }

    func savePhoto(_ photo: Photo) async throws {
        try await photoStorageService.savePhoto(photo)
    }

    func detectData(in ciImage: CIImage, for category: FilterCategory) async throws -> DetectionData {
        switch category {
        case .sizes:
            let faceResult = try await faceTrackingService.detectFaces(in: ciImage)
            return DetectionData.faceLandmarks(faceResult)
        case .hair:
            let hairResult = try await hairSegmentationService.segmentHair(in: ciImage)
            return DetectionData.hairSegmentation(hairResult)
        }
    }
}
