//
//  PhotoEditorApplicationService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import CoreImage

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
        let detectionData = if let detectionData {
            detectionData
        } else {
            try await detectData(in: photo.originalImage, for: configuration.filter.category)
        }

        let processedImage = try filterProcessingService.applyFilters(
            to: photo.originalImage,
            with: configuration,
            detectionData: detectionData
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
            .faceLandmarks(try await faceTrackingService.detectFaces(in: ciImage))
        case .hair:
            .hairSegmentation(try await hairSegmentationService.segmentHair(in: ciImage))
        }
    }
}
