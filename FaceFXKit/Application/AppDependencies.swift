//
//  AppDependencies.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation

@MainActor
final class AppDependencies {
    let ciContextStore = CIContextStore()
    let photoPickingService = PhotosUIPickingService()
    let photoStorageService: PhotoStorageService
    let filterProcessingService: FilterProcessingService = DefaultFilterProcessingService()
    let faceTrackingService: VisionFaceTrackingService = DefaultVisionFaceTrackingService()
    let hairSegmentationService: HairSegmentationService = try! DefaultHairSegmentationService()
    let photoEditorApplicationService: PhotoEditorApplicationService

    init() {
        photoStorageService = DefaultPhotoStorageService(ciContextStore: ciContextStore)

        photoEditorApplicationService = PhotoEditorApplicationService(
            filterProcessingService: filterProcessingService,
            photoStorageService: photoStorageService,
            faceTrackingService: faceTrackingService,
            hairSegmentationService: hairSegmentationService
        )
    }
}
