//
//  PhotoPickingService.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import PhotosUI
import _PhotosUI_SwiftUI

protocol PhotoPickingService: Observable {
    var selectedImage: UIImage? { get }
    @MainActor
    func handlePhotoSelection(_ item: PhotosPickerItem) async throws
    func clearSelection()
}

@Observable
final class PhotosUIPickingService: PhotoPickingService {
    enum PhotoPickingError: Error {
        case invalidImageData
    }

    var selectedImage: UIImage?

    @MainActor
    func handlePhotoSelection(_ item: PhotosPickerItem) async throws {
        if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
            selectedImage = image
        } else {
            throw PhotoPickingError.invalidImageData
        }
    }
    
    func clearSelection() {
        selectedImage = nil
    }
}

