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
    let imageSize: CGSize
    let imageScale: CGFloat
    let imageOffset: CGSize
    let opacity: Double
    
    @State private var imageFrameLocal: CGRect = .zero
    @State private var overlayImage: CGImage?
    
    init(
        hairData: HairSegmentationResult,
        imageSize: CGSize,
        imageScale: CGFloat,
        imageOffset: CGSize,
        opacity: Double = 0.6
    ) {
        self.hairData = hairData
        self.imageSize = imageSize
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
        .onAppear {
            generateOverlayImage()
        }
        .onChange(of: hairData.originalHairMask) { _, _ in
            generateOverlayImage()
        }
    }
    
    private func generateOverlayImage() {
        Task {
            let image = await createColoredHairMask()
            await MainActor.run {
                self.overlayImage = image
            }
        }
    }
    
    private func createColoredHairMask() async -> CGImage? {
        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        colorMatrix.setValue(hairData.originalHairMask, forKey: kCIInputImageKey)

        colorMatrix.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0.0, y: 1.0, z: 1.0, w: 0.0), forKey: "inputBVector")
        colorMatrix.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0), forKey: "inputAVector")
        
        guard let coloredMask = colorMatrix.outputImage else { return nil }

        let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
        return context.createCGImage(coloredMask, from: coloredMask.extent)
    }
}
