//
//  FilterRepository.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

protocol FilterRepository {
    func applyFilters(to image: CIImage, with configuration: FilterConfiguration, detectionData: DetectionData?) async throws -> CIImage
    func getAvailableFilters() -> [FilterType]
} 
