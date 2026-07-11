//
//  EditorImageCanvas.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

/// The zoomable, pannable photo with its detection overlays. Extracted so that
/// per-frame gesture updates only invalidate this view, not the filter panels.
struct EditorImageCanvas: View {
    let viewModel: EditorViewModel
    let containerSize: CGSize

    var body: some View {
        if let image = viewModel.previewImage {
            MetalImageView(image: image)
                .aspectRatio(
                    image.extent.width / max(image.extent.height, 1),
                    contentMode: .fit
                )
                .accessibilityLabel("Photo")
                .scaleEffect(viewModel.zoomPan.scale)
                .offset(viewModel.zoomPan.offset)
                .gesture(
                    SimultaneousGesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newScale = viewModel.zoomPan.lastScale * value.magnification
                                viewModel.updateScale(newScale, in: containerSize)
                            }
                            .onEnded { value in
                                let newScale = viewModel.zoomPan.lastScale * value.magnification
                                viewModel.updateScale(newScale, in: containerSize)
                                viewModel.finalizeScale()
                            },
                        DragGesture()
                            .onChanged { value in
                                viewModel.updateOffset(value.translation, in: containerSize)
                            }
                            .onEnded { _ in
                                viewModel.finalizeOffset()
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    viewModel.resetZoom()
                }
                .overlay {
                    if
                        viewModel.showLandmarks,
                        let detectionData = viewModel.cachedDetectionData,
                        let faceData = detectionData.faceTrackingResult
                    {
                        FaceLandmarksOverlayView(
                            faceData: faceData,
                            imageScale: viewModel.zoomPan.scale,
                            imageOffset: viewModel.zoomPan.offset
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if
                        viewModel.showHairMask,
                        let detectionData = viewModel.cachedDetectionData,
                        let hairData = detectionData.hairSegmentationResult
                    {
                        HairMaskOverlayView(
                            hairData: hairData,
                            imageScale: viewModel.zoomPan.scale,
                            imageOffset: viewModel.zoomPan.offset
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
        }
    }
}
