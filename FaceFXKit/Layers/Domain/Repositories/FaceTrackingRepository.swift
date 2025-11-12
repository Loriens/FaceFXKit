//
//  FaceTrackingRepository.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import CoreImage

protocol FaceTrackingRepository {
    func detectFaces(in ciImage: CIImage) async throws -> FaceTrackingResult
}
