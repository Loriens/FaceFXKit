//
//  ApplyFiltersUseCase.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

protocol ApplyFiltersUseCase: Sendable {
    func execute(
        photo: Photo,
        configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) async throws -> Photo
}

final class DefaultApplyFiltersUseCase: ApplyFiltersUseCase, @unchecked Sendable {
    private let photoProcessingService: PhotoProcessingService
    
    init(photoProcessingService: PhotoProcessingService) {
        self.photoProcessingService = photoProcessingService
    }
    
    func execute(
        photo: Photo,
        configuration: FilterConfiguration,
        detectionData: DetectionData? = nil
    ) async throws -> Photo {
        return try await photoProcessingService.processPhoto(
            photo,
            with: configuration,
            detectionData: detectionData
        )
    }
}

enum PhotoProcessingError: Error {
    case invalidPhoto
    case processingFailed
    case unsupportedFormat
} 
