//
//  PhotoProcessingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

protocol PhotoProcessingService {
    func processPhoto(
        _ photo: Photo,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) async throws -> Photo
}

final class DefaultPhotoProcessingService: PhotoProcessingService {
    private let filterRepository: FilterRepository
    private let faceTrackingRepository: FaceTrackingRepository
    private let hairSegmentationRepository: HairSegmentationRepository

    init(filterRepository: FilterRepository, faceTrackingRepository: FaceTrackingRepository, hairSegmentationRepository: HairSegmentationRepository) {
        self.filterRepository = filterRepository
        self.faceTrackingRepository = faceTrackingRepository
        self.hairSegmentationRepository = hairSegmentationRepository
    }

    func processPhoto(
        _ photo: Photo,
        with configuration: FilterConfiguration,
        detectionData: DetectionData? = nil
    ) async throws -> Photo {
        var finalDetectionData = detectionData

        if finalDetectionData == nil {
            let activeFilters = [configuration.filter]
            let needsFaceDetection = activeFilters.contains(where: { $0.category == .sizes })
            let needsHairSegmentation = activeFilters.contains(where: { $0.category == .hair })
            
            if needsFaceDetection, needsHairSegmentation {
                let faceResult = try await faceTrackingRepository.detectFaces(in: photo.originalImage)
                let hairResult = try await hairSegmentationRepository.segmentHair(in: photo.originalImage)

                let (faces, hair) = (faceResult, hairResult)
                finalDetectionData = DetectionData.combined(faces: faces, hair: hair)
            } else if needsFaceDetection {
                let faceResult = try await faceTrackingRepository.detectFaces(in: photo.originalImage)
                finalDetectionData = DetectionData.faceLandmarks(faceResult)
            } else if needsHairSegmentation {
                let hairResult = try await hairSegmentationRepository.segmentHair(in: photo.originalImage)
                finalDetectionData = DetectionData.hairSegmentation(hairResult)
            }
        }
        
        let processedImage = try await filterRepository.applyFilters(to: photo.originalImage, with: configuration, detectionData: finalDetectionData)

        var updatedPhoto = photo
        updatedPhoto.updateProcessedImage(processedImage)
        return updatedPhoto
    }
}
