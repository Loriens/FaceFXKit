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
    let ciContext: CIContext

    var body: some View {
        GeometryReader { geometry in
            photo(containerSize: geometry.size)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .overlay(alignment: .topLeading) {
            compareBadge
                .padding(12)
        }
        .overlay(alignment: .bottomTrailing) {
            compareButton
                .padding(12)
        }
        .overlay {
            if viewModel.isDetecting {
                AnalyzingOverlay(category: viewModel.selectedCategory)
                    .transition(.opacity)
            }
        }
        .clipped()
    }

    private func photo(containerSize: CGSize) -> some View {
        let image = viewModel.previewImage

        return MetalImageView(image: image)
            .aspectRatio(image.extent.width / max(image.extent.height, 1), contentMode: .fit)
            .accessibilityLabel("Photo")
            .scaleEffect(viewModel.zoomPan.scale)
            .offset(viewModel.zoomPan.offset)
            .gesture(SimultaneousGesture(magnifyGesture(in: containerSize), dragGesture(in: containerSize)))
            .onTapGesture(count: 2) {
                viewModel.resetZoom()
            }
            .overlay {
                overlays
            }
    }

    @ViewBuilder
    private var overlays: some View {
        let zoomPan = viewModel.zoomPan

        if !viewModel.isComparing, viewModel.isOverlayVisible {
            switch viewModel.currentDetectionData {
            case .faceLandmarks(let faceData):
                FaceLandmarksOverlayView(faceData: faceData, imageScale: zoomPan.scale, imageOffset: zoomPan.offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .hairSegmentation(let hairData):
                HairMaskOverlayView(
                    hairData: hairData,
                    imageScale: zoomPan.scale,
                    imageOffset: zoomPan.offset,
                    ciContext: ciContext
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case nil:
                EmptyView()
            }
        }
    }

    private var compareBadge: some View {
        Text(viewModel.isComparing ? "Before" : "After")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .textCase(.uppercase)
            .tracking(0.66)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(Color.floatingFill, in: .capsule)
            .allowsHitTesting(false)
    }

    private var compareButton: some View {
        let isComparing = viewModel.isComparing

        return Button(action: viewModel.toggleCompare) {
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isComparing ? Color.onAccent : Color.textPrimary)
                .frame(width: 44, height: 44)
                .background(isComparing ? Color.textPrimary : Color.floatingFill, in: .circle)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Compare with original")
        .accessibilityAddTraits(isComparing ? .isSelected : [])
    }

    private func magnifyGesture(in containerSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                viewModel.updateScale(viewModel.zoomPan.lastScale * value.magnification, in: containerSize)
            }
            .onEnded { value in
                viewModel.updateScale(viewModel.zoomPan.lastScale * value.magnification, in: containerSize)
                viewModel.finalizeScale()
            }
    }

    private func dragGesture(in containerSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.updateOffset(value.translation, in: containerSize)
            }
            .onEnded { _ in
                viewModel.finalizeOffset()
            }
    }
}
