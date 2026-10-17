//
//  EditorView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import SwiftUI
import CoreImage

struct EditorView: View {
    @State private var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    private let ciContext: CIContext

    init(photo: Photo, applicationService: PhotoEditorApplicationService, ciContext: CIContext) {
        self.ciContext = ciContext
        // The view model is created once per view identity. The caller applies
        // `.id(photo.id)` so a different photo always produces a fresh editor.
        _viewModel = State(initialValue: EditorViewModel(photo: photo, applicationService: applicationService))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)

                EditorImageCanvas(viewModel: viewModel, containerSize: geometry.size, ciContext: ciContext)

                if viewModel.isFaceDetecting {
                    DetectionProgressView(category: viewModel.selectedCategory)
                }
            }
            .overlay(alignment: .bottom) {
                FilterControlPanel(viewModel: viewModel)
            }
            .clipped()
        }
        .overlay(alignment: .top) {
            EditorTopBar(viewModel: viewModel) {
                dismiss()
            }
        }
        .background(Color(.systemBackground))
        .toolbarVisibility(.hidden, for: .navigationBar)
        .errorAlert(message: $viewModel.errorMessage)
        .onDisappear {
            viewModel.cancelPendingWork()
        }
    }
}

/// Progress indicator shown while detection runs for a selected category.
struct DetectionProgressView: View {
    let category: FilterCategory?

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)

            Text(category == .hair ? "Analyzing hair..." : "Detecting faces...")
                .foregroundStyle(.white)
                .font(.headline)
        }
    }
}
