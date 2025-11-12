//
//  FaceTrackingRepositoryImpl.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import CoreImage

final class FaceTrackingRepositoryImpl: FaceTrackingRepository {
    private let visionFaceTrackingService: VisionFaceTrackingService
    
    init(visionFaceTrackingService: VisionFaceTrackingService) {
        self.visionFaceTrackingService = visionFaceTrackingService
    }
    
    func detectFaces(in ciImage: CIImage) async throws -> FaceTrackingResult {
        return try await visionFaceTrackingService.detectFaces(in: ciImage)
    }
} 
