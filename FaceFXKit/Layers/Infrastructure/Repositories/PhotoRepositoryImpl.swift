//
//  PhotoRepositoryImpl.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit

final class PhotoRepositoryImpl: PhotoRepository {
    private let photoStorageService: PhotoStorageService
    
    init(photoStorageService: PhotoStorageService) {
        self.photoStorageService = photoStorageService
    }
    
    func savePhoto(_ photo: Photo) async throws {
        try await photoStorageService.savePhoto(photo)
    }
} 
