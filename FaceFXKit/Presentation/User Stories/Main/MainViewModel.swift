//
//  MainViewModel.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import SwiftUI
import PhotosUI

@MainActor
@Observable
final class MainViewModel {
    var showingEditor = false
    var selectedPhoto: Photo?
    var isLoading = false
    var errorMessage: String?

    private let photoPickingService: PhotosUIPickingService

    init(photoPickingService: PhotosUIPickingService) {
        self.photoPickingService = photoPickingService
    }

    func selectPhotoFromGallery(item: PhotosPickerItem) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await photoPickingService.handlePhotoSelection(item)
            if let selectedImage = photoPickingService.selectedImage {
                selectedPhoto = Photo(image: selectedImage)
                showingEditor = true
                photoPickingService.clearSelection()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
