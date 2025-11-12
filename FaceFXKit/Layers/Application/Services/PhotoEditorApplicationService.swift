//
//  PhotoEditorApplicationService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import CoreImage

@Observable
final class PhotoEditorApplicationService: @unchecked Sendable {
    private let applyFiltersUseCase: ApplyFiltersUseCase
    private let photoRepository: PhotoRepository
    private let faceTrackingRepository: FaceTrackingRepository
    private let hairSegmentationRepository: HairSegmentationRepository
    
    init(
        applyFiltersUseCase: ApplyFiltersUseCase,
        photoRepository: PhotoRepository,
        faceTrackingRepository: FaceTrackingRepository,
        hairSegmentationRepository: HairSegmentationRepository
    ) {
        self.applyFiltersUseCase = applyFiltersUseCase
        self.photoRepository = photoRepository
        self.faceTrackingRepository = faceTrackingRepository
        self.hairSegmentationRepository = hairSegmentationRepository
    }
    
    func applyFilters(
        to photo: Photo,
        configuration: FilterConfiguration,
        detectionData: DetectionData? = nil
    ) async throws -> Photo {
        return try await applyFiltersUseCase.execute(
            photo: photo,
            configuration: configuration,
            detectionData: detectionData
        )
    }
    
    func savePhoto(_ photo: Photo) async throws {
        try await photoRepository.savePhoto(photo)
    }
    
    func detectData(in ciImage: CIImage, for category: FilterCategory) async throws -> DetectionData {
        switch category {
        case .sizes:
            let faceResult = try await faceTrackingRepository.detectFaces(in: ciImage)
            return DetectionData.faceLandmarks(faceResult)
        case .hair:
            let hairResult = try await hairSegmentationRepository.segmentHair(in: ciImage)
            return DetectionData.hairSegmentation(hairResult)
        }
    }
} 
