//
//  ImageZoomPanModel.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

struct ImageZoomPanModel {
    private(set) var scale: CGFloat = 1.0
    private(set) var offset: CGSize = .zero
    private(set) var lastScale: CGFloat = 1.0
    private(set) var lastOffset: CGSize = .zero

    private static let minimumOvershootScale: CGFloat = 0.7
    private static let minimumScale: CGFloat = 1.0
    private static let maximumScale: CGFloat = 5.0

    mutating func reset() {
        self = ImageZoomPanModel()
    }

    mutating func updateScale(_ newScale: CGFloat, imagePixelSize: CGSize, containerSize: CGSize) {
        scale = min(max(newScale, Self.minimumOvershootScale), Self.maximumScale)
        offset = clampedOffset(offset, imagePixelSize: imagePixelSize, containerSize: containerSize)
    }

    mutating func finalizeScale() {
        let constrainedScale = min(max(scale, Self.minimumScale), Self.maximumScale)

        if scale < Self.minimumScale {
            scale = constrainedScale
            offset = .zero
        }

        lastScale = constrainedScale
        lastOffset = offset
    }

    mutating func updateOffset(translation: CGSize, imagePixelSize: CGSize, containerSize: CGSize) {
        let proposedOffset = CGSize(
            width: lastOffset.width + translation.width,
            height: lastOffset.height + translation.height
        )
        offset = clampedOffset(proposedOffset, imagePixelSize: imagePixelSize, containerSize: containerSize)
    }

    mutating func finalizeOffset() {
        lastOffset = offset
    }

    // MARK: - Geometry

    private func clampedOffset(
        _ proposedOffset: CGSize,
        imagePixelSize: CGSize,
        containerSize: CGSize
    ) -> CGSize {
        guard scale >= Self.minimumScale else { return .zero }

        let fittedSize = Self.fittedSize(of: imagePixelSize, in: containerSize)
        let maxOffsetX = max(0, (fittedSize.width * scale - containerSize.width) / 2)
        let maxOffsetY = max(0, (fittedSize.height * scale - containerSize.height) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -maxOffsetX), maxOffsetX),
            height: min(max(proposedOffset.height, -maxOffsetY), maxOffsetY)
        )
    }

    /// Size of the image after aspect-fitting it into the container.
    private static func fittedSize(of imagePixelSize: CGSize, in containerSize: CGSize) -> CGSize {
        guard imagePixelSize.height > 0, containerSize.height > 0 else { return .zero }

        let imageAspectRatio = imagePixelSize.width / imagePixelSize.height
        let containerAspectRatio = containerSize.width / containerSize.height

        if imageAspectRatio > containerAspectRatio {
            // Image is wider than container
            return CGSize(width: containerSize.width, height: containerSize.width / imageAspectRatio)
        }
        // Image is taller than container
        return CGSize(width: containerSize.height * imageAspectRatio, height: containerSize.height)
    }
}
