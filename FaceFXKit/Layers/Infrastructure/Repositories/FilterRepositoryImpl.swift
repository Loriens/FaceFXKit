//
//  FilterRepositoryImpl.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

final class FilterRepositoryImpl: FilterRepository {
    private let filterProcessingService: FilterProcessingService
    
    init(filterProcessingService: FilterProcessingService) {
        self.filterProcessingService = filterProcessingService
    }
    
    func applyFilters(
        to image: CIImage,
        with configuration: FilterConfiguration,
        detectionData: DetectionData?
    ) async throws -> CIImage {
        try filterProcessingService.applyFilters(to: image, with: configuration, detectionData: detectionData)
    }
    
    func getAvailableFilters() -> [FilterType] {
        return FilterType.allCases
    }
} 
