//
//  PhotoRepository.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

protocol PhotoRepository {
    func savePhoto(_ photo: Photo) async throws
} 
