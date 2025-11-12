//
//  HairSegmentationRepository.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 29/07/2025.
//

import Foundation
import UIKit
import CoreImage

protocol HairSegmentationRepository {
    func segmentHair(in ciImage: CIImage) async throws -> HairSegmentationResult
}
