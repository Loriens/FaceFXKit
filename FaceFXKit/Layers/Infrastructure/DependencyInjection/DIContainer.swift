//
//  DIContainer.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

/// Composition root. `@MainActor` because it is only touched during view and
/// view-model construction; `let` properties make the graph immutable after
/// the one-time initialization.
@MainActor
final class DIContainer {
    static let shared = DIContainer()

    // MARK: - Infrastructure Services

    let ciContextStore: CIContextStore
    let photoPickingService: PhotosUIPickingService
    let photoStorageService: PhotoStorageService
    let filterProcessingService: FilterProcessingService
    let faceTrackingService: VisionFaceTrackingService
    let hairSegmentationService: HairSegmentationService

    // MARK: - Application Services

    let photoEditorApplicationService: PhotoEditorApplicationService

    private init() {
        let ciContextStore = CIContextStore()
        self.ciContextStore = ciContextStore
        self.photoPickingService = PhotosUIPickingService()

        let photoStorageService = DefaultPhotoStorageService(ciContextStore: ciContextStore)
        self.photoStorageService = photoStorageService

        let filterProcessingService = DefaultFilterProcessingService()
        self.filterProcessingService = filterProcessingService

        let faceTrackingService = DefaultVisionFaceTrackingService()
        self.faceTrackingService = faceTrackingService

        let hairSegmentationService = try! DefaultHairSegmentationService()
        self.hairSegmentationService = hairSegmentationService

        self.photoEditorApplicationService = PhotoEditorApplicationService(
            filterProcessingService: filterProcessingService,
            photoStorageService: photoStorageService,
            faceTrackingService: faceTrackingService,
            hairSegmentationService: hairSegmentationService
        )
    }
}
