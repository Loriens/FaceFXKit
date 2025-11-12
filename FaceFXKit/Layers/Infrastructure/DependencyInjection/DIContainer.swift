//
//  DIContainer.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

final class DIContainer {
    @MainActor static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Infrastructure Services

    lazy var ciContextStore: CIContextStore = {
        return CIContextStore()
    }()
    
    lazy var photoPickingService: PhotoPickingService = {
        return PhotosUIPickingService()
    }()
    
    lazy var photoStorageService: PhotoStorageService = {
        return DefaultPhotoStorageService(ciContextStore: ciContextStore)
    }()
    
    lazy var filterProcessingService: FilterProcessingService = {
        return DefaultFilterProcessingService(ciContextStore: ciContextStore)
    }()
    
    lazy var visionFaceTrackingService: VisionFaceTrackingService = {
        return DefaultVisionFaceTrackingService()
    }()
    
    lazy var hairSegmentationService: HairSegmentationService = {
        return try! DefaultHairSegmentationService()
    }()
    
    // MARK: - Repositories

    lazy var photoRepository: PhotoRepository = {
        return PhotoRepositoryImpl(
            photoStorageService: photoStorageService
        )
    }()
    
    lazy var filterRepository: FilterRepository = {
        return FilterRepositoryImpl(
            filterProcessingService: filterProcessingService
        )
    }()
    
    lazy var faceTrackingRepository: FaceTrackingRepository = {
        return FaceTrackingRepositoryImpl(
            visionFaceTrackingService: visionFaceTrackingService
        )
    }()
    
    lazy var hairSegmentationRepository: HairSegmentationRepository = {
        return HairSegmentationRepositoryImpl(
            hairSegmentationService: hairSegmentationService
        )
    }()
    
    // MARK: - Domain Services

    lazy var photoProcessingService: PhotoProcessingService = {
        return DefaultPhotoProcessingService(
            filterRepository: filterRepository,
            faceTrackingRepository: faceTrackingRepository,
            hairSegmentationRepository: hairSegmentationRepository
        )
    }()
    
    // MARK: - Use Cases

    lazy var applyFiltersUseCase: ApplyFiltersUseCase = {
        return DefaultApplyFiltersUseCase(
            photoProcessingService: photoProcessingService
        )
    }()
    
    // MARK: - Application Services

    lazy var photoEditorApplicationService: PhotoEditorApplicationService = {
        return PhotoEditorApplicationService(
            applyFiltersUseCase: applyFiltersUseCase,
            photoRepository: photoRepository,
            faceTrackingRepository: faceTrackingRepository,
            hairSegmentationRepository: hairSegmentationRepository
        )
    }()
} 
