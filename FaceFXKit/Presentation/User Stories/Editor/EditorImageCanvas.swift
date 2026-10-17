//
//  EditorImageCanvas.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI
import CoreImage

struct EditorImageCanvas: View {
    let viewModel: EditorViewModel
    let containerSize: CGSize
    let ciContext: CIContext

    var body: some View {
        if let image = viewModel.previewImage {
            MetalImageView(image: image)
                .aspectRatio(image.extent.width / max(image.extent.height, 1), contentMode: .fit)
                .accessibilityLabel("Photo")
                .scaleEffect(viewModel.zoomPan.scale)
                .offset(viewModel.zoomPan.offset)
                .gesture(SimultaneousGesture(magnifyGesture, dragGesture))
                .onTapGesture(count: 2) {
                    viewModel.resetZoom()
                }
                .overlay {
                    overlays
                }
        }
    }

    @ViewBuilder
    private var overlays: some View {
        let zoomPan = viewModel.zoomPan

        if viewModel.showLandmarks, let faceData = viewModel.cachedDetectionData?.faceTrackingResult {
            FaceLandmarksOverlayView(faceData: faceData, imageScale: zoomPan.scale, imageOffset: zoomPan.offset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        if viewModel.showHairMask, let hairData = viewModel.cachedDetectionData?.hairSegmentationResult {
            HairMaskOverlayView(
                hairData: hairData,
                imageScale: zoomPan.scale,
                imageOffset: zoomPan.offset,
                ciContext: ciContext
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                viewModel.updateScale(viewModel.zoomPan.lastScale * value.magnification, in: containerSize)
            }
            .onEnded { value in
                viewModel.updateScale(viewModel.zoomPan.lastScale * value.magnification, in: containerSize)
                viewModel.finalizeScale()
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.updateOffset(value.translation, in: containerSize)
            }
            .onEnded { _ in
                viewModel.finalizeOffset()
            }
    }
}
