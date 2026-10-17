//
//  EditorTopBar.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

struct EditorTopBar: View {
    let viewModel: EditorViewModel
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Button(viewModel.isShowingFilters ? "Back" : "Close", action: goBack)
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 8) {
                if viewModel.cachedDetectionData?.faceTrackingResult != nil {
                    overlayToggle(viewModel.showLandmarks ? "Hide Points" : "Show Points", action: viewModel.toggleLandmarks)
                }

                if viewModel.cachedDetectionData?.hairSegmentationResult != nil {
                    overlayToggle(viewModel.showHairMask ? "Hide Hair" : "Show Hair", action: viewModel.toggleHairMask)
                }
            }

            Button("Save") {
                Task {
                    if await viewModel.savePhoto() {
                        dismiss()
                    }
                }
            }
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private func goBack() {
        if viewModel.isShowingIndividualFilters {
            viewModel.backToGroupFilters()
        } else if viewModel.isShowingFilters {
            viewModel.backToCategories()
        } else {
            dismiss()
        }

        viewModel.resetAllFilters()
    }

    private func overlayToggle(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6), in: .rect(cornerRadius: 6))
    }
}
