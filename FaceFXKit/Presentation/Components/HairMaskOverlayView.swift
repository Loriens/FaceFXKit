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
    var opacity = 0.45

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
            }
        }
        .allowsHitTesting(false)
        .task(id: hairData.originalHairMask) {
            overlayImage = await Self.createColoredHairMask(
                from: hairData.originalHairMask,
                tint: CIColor(color: UIColor(resource: .accent)),
                using: ciContext
            )
        }
    }

    @concurrent
    private nonisolated static func createColoredHairMask(
        from hairMask: CIImage,
        tint: CIColor,
        using context: CIContext
    ) async -> CGImage? {
        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        colorMatrix.setValue(hairMask, forKey: kCIInputImageKey)
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        colorMatrix.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputAVector")
        colorMatrix.setValue(CIVector(x: tint.red, y: tint.green, z: tint.blue, w: 0), forKey: "inputBiasVector")

        guard let coloredMask = colorMatrix.outputImage else { return nil }

        return context.createCGImage(coloredMask, from: coloredMask.extent)
    }
}
