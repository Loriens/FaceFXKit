//
//  PhotoStorageService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Photos

protocol PhotoStorageService {
    func savePhoto(_ photo: Photo) async throws
}

final class DefaultPhotoStorageService: PhotoStorageService {
    enum PhotoStorageError: LocalizedError {
        case imageConversionFailed
        case photosAccessDenied
        case photosSaveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed: "Failed to render the edited photo"
            case .photosAccessDenied: "Allow photo library access in Settings to save photos"
            case .photosSaveFailed(let error): "Failed to save photo: \(error.localizedDescription)"
            }
        }
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
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard status == .notDetermined else { return status }
        return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}
