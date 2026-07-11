//
//  HairMaskOverlayView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 29/07/2025.
//

import SwiftUI
import CoreImage

struct HairMaskOverlayView: View {
    let hairData: HairSegmentationResult
    let imageScale: CGFloat
    let imageOffset: CGSize
    let opacity: Double

    @State private var overlayImage: CGImage?

    init(
        hairData: HairSegmentationResult,
        imageScale: CGFloat,
        imageOffset: CGSize,
        opacity: Double = 0.6
    ) {
        self.hairData = hairData
        self.imageScale = imageScale
        self.imageOffset = imageOffset
        self.opacity = opacity
    }

    var body: some View {
        ZStack {
            if let overlayImage {
                Image(overlayImage, scale: 1.0, label: Text("Hair Mask"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .opacity(opacity)
                    .blendMode(.multiply)
            }
        }
        // `.task(id:)` cancels and restarts the render when the mask changes and
        // on disappear, so a stale render can never overwrite a newer one.
        .task(id: hairData.originalHairMask) {
            let context = DIContainer.shared.ciContextStore.primaryContext
            overlayImage = await Self.createColoredHairMask(
                from: hairData.originalHairMask,
                using: context
            )
        }
    }

    /// Renders the tinted hair mask off the main actor using the shared context.
    @concurrent
    private nonisolated static func createColoredHairMask(
        from hairMask: CIImage,
        using context: CIContext
    ) async -> CGImage? {
        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        colorMatrix.setValue(hairMask, forKey: kCIInputImageKey)

        colorMatrix.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0.0, y: 1.0, z: 1.0, w: 0.0), forKey: "inputBVector")
        colorMatrix.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0), forKey: "inputAVector")

        guard let coloredMask = colorMatrix.outputImage else { return nil }

        return context.createCGImage(coloredMask, from: coloredMask.extent)
    }
}
