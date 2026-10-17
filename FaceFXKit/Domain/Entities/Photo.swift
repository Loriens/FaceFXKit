//
//  Photo.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import UIKit
import CoreImage

struct Photo: @unchecked Sendable {
    let id = UUID()
    let originalImage: CIImage
    let createdAt = Date()
    
    private(set) var processedImage: CIImage?
    private(set) var lastModified = Date()

    var currentImage: CIImage {
        processedImage ?? originalImage
    }

    init(image: UIImage) {
        originalImage = CIImage(image: image)?
            .oriented(forExifOrientation: image.imageOrientationToTiffOrientation()) ?? CIImage()
    }

    mutating func updateProcessedImage(_ image: CIImage) {
        processedImage = image
        lastModified = Date()
    }

    func currentUIImage(using contextStore: CIContextStore) -> UIImage? {
        contextStore
            .primaryContext
            .createCGImage(currentImage, from: currentImage.extent)
            .map(UIImage.init(cgImage:))
    }
}
