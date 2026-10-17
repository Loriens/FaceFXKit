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
    let ciContext: CIContext
    var opacity = 0.6

    @State private var overlayImage: CGImage?

    var body: some View {
        ZStack {
            if let overlayImage {
                Image(overlayImage, scale: 1, label: Text("Hair Mask"))
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
            overlayImage = await Self.createColoredHairMask(
                from: hairData.originalHairMask,
                using: ciContext
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
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0, y: 1, z: 1, w: 0), forKey: "inputBVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")

        guard let coloredMask = colorMatrix.outputImage else { return nil }

        return context.createCGImage(coloredMask, from: coloredMask.extent)
    }
}
