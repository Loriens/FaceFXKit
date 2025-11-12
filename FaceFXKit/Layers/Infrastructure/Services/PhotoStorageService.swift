//
//  PhotoStorageService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import Photos

protocol PhotoStorageService {
    func savePhoto(_ photo: Photo) async throws
}

final class DefaultPhotoStorageService: PhotoStorageService {
    enum PhotoStorageError: Error {
        case imageConversionFailed
        case photosAccessDenied
        case photosSaveFailed(Error)
    }

    private let ciContextStore: CIContextStore

    init(ciContextStore: CIContextStore) {
        self.ciContextStore = ciContextStore
    }
    
    func savePhoto(_ photo: Photo) async throws {
        guard let uiImage = photo.currentUIImage(using: ciContextStore) else {
            throw PhotoStorageError.imageConversionFailed
        }

        let status = await requestPhotosPermission()

        guard status == .authorized || status == .limited else {
            throw PhotoStorageError.photosAccessDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            }
        } catch {
            throw PhotoStorageError.photosSaveFailed(error)
        }
    }
    
    private func requestPhotosPermission() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch currentStatus {
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        default:
            return currentStatus
        }
    }
} 
