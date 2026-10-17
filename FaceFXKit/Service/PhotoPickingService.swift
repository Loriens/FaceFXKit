//
//  PhotoPickingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import SwiftUI
import PhotosUI

protocol PhotoPickingService: Observable {
    var selectedImage: UIImage? { get }
    @MainActor
    func handlePhotoSelection(_ item: PhotosPickerItem) async throws
    func clearSelection()
}

@Observable
final class PhotosUIPickingService: PhotoPickingService {
    enum PhotoPickingError: LocalizedError {
        case invalidImageData

        var errorDescription: String? { "The selected photo could not be loaded" }
    }

    var selectedImage: UIImage?

    @MainActor
    func handlePhotoSelection(_ item: PhotosPickerItem) async throws {
        guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            throw PhotoPickingError.invalidImageData
        }
        selectedImage = image
    }

    func clearSelection() {
        selectedImage = nil
    }
}
