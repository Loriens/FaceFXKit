//
//  Photo.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import UIKit
import CoreImage

struct Photo: @unchecked Sendable {
    let id: UUID
    let originalImage: CIImage
    var processedImage: CIImage?
    let createdAt: Date
    var lastModified: Date

    var currentImage: CIImage {
        return processedImage ?? originalImage
    }

    init(image: UIImage) {
        self.id = UUID()
        self.originalImage = CIImage(image: image)?.oriented(forExifOrientation: image.imageOrientationToTiffOrientation()) ?? CIImage()
        self.processedImage = nil
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    mutating func updateProcessedImage(_ image: CIImage) {
        self.processedImage = image
        self.lastModified = Date()
    }

    func currentUIImage(using contextStore: CIContextStore) -> UIImage? {
        let ciImage = currentImage
        guard let cgImage = contextStore.createCGImage(from: ciImage) else { return nil }
        return UIImage(cgImage: cgImage)
    }
} 
