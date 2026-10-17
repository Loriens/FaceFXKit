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
        _viewModel = State(initialValue: EditorViewModel(photo: photo, applicationService: applicationService))
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorTopBar(viewModel: viewModel) {
                dismiss()
            }

            EditorImageCanvas(viewModel: viewModel, ciContext: ciContext)
                .padding(.top, 8)

            FilterControlPanel(viewModel: viewModel)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .foregroundStyle(Color.textPrimary)
        .background(Color.appBackground)
        .overlay {
            if viewModel.isShowingSavedConfirmation {
                SavedConfirmationSheet(
                    appliedEdits: viewModel.appliedConfigurations.map { $0.filter.appliedSummary(intensity: $0.intensity) },
                    keepEditing: viewModel.dismissSavedConfirmation,
                    newPhoto: { dismiss() }
                )
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .errorAlert(message: $viewModel.errorMessage)
        .onDisappear {
            viewModel.cancelPendingWork()
        }
    }
}
