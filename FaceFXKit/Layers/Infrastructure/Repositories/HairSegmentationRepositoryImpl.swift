//
//  HairSegmentationRepositoryImpl.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 29/07/2025.
//

import Foundation
import UIKit
import CoreImage

final class HairSegmentationRepositoryImpl: HairSegmentationRepository {
    private let hairSegmentationService: HairSegmentationService
    
    init(hairSegmentationService: HairSegmentationService) {
        self.hairSegmentationService = hairSegmentationService
    }
    
    func segmentHair(in ciImage: CIImage) async throws -> HairSegmentationResult {
        return try await hairSegmentationService.segmentHair(in: ciImage)
    }
}
