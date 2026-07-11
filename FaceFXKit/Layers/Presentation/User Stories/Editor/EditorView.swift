//
//  EditorView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import SwiftUI

struct EditorView: View {
    @State private var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    init(photo: Photo) {
        // The view model is created once per view identity. The caller applies
        // `.id(photo.id)` so a different photo always produces a fresh editor.
        let applicationService = DIContainer.shared.photoEditorApplicationService
        _viewModel = State(initialValue: EditorViewModel(photo: photo, applicationService: applicationService))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    Color(.systemBackground)

                    EditorImageCanvas(viewModel: viewModel, containerSize: geometry.size)

                    if viewModel.isFaceDetecting {
                        DetectionProgressView(category: viewModel.selectedCategory)
                    }

                    VStack {
                        Spacer()
                        FilterControlPanel(viewModel: viewModel)
                    }
                }
                .clipped()
            }

            VStack {
                EditorTopBar(viewModel: viewModel) {
                    dismiss()
                }
                Spacer()
            }
        }
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
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.5)

            Text(category == .hair ? "Analyzing hair..." : "Detecting faces...")
                .foregroundStyle(.white)
                .font(.headline)
        }
    }
}
