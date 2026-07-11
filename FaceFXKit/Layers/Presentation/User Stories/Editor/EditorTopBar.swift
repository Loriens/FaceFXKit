//
//  EditorTopBar.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

/// Top bar: back/close navigation, overlay toggles, and save.
struct EditorTopBar: View {
    let viewModel: EditorViewModel
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Button(viewModel.isShowingFilters ? "Back" : "Close") {
                if viewModel.isShowingIndividualFilters {
                    viewModel.backToGroupFilters()
                } else if viewModel.isShowingFilters {
                    viewModel.backToCategories()
                } else {
                    dismiss()
                }

                viewModel.resetAllFilters()
            }
            .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 8) {
                if viewModel.cachedDetectionData?.faceTrackingResult != nil {
                    overlayToggle(viewModel.showLandmarks ? "Hide Points" : "Show Points") {
                        viewModel.toggleLandmarks()
                    }
                }

                if viewModel.cachedDetectionData?.hairSegmentationResult != nil {
                    overlayToggle(viewModel.showHairMask ? "Hide Hair" : "Show Hair") {
                        viewModel.toggleHairMask()
                    }
                }
            }

            Button("Save") {
                Task {
                    await viewModel.savePhoto()
                    dismiss()
                }
            }
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
        )
    }

    private func overlayToggle(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 6))
    }
}
