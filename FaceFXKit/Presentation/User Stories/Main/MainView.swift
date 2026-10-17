//
//  MainView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import SwiftUI
import PhotosUI

struct MainView: View {
    @State private var viewModel: MainViewModel
    @State private var imageSelection: PhotosPickerItem?
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: MainViewModel(photoPickingService: dependencies.photoPickingService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "faceid")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.onAccent)
                        .frame(width: 64, height: 64)
                        .background(Color.accent, in: .rect(cornerRadius: 18))
                        .accessibilityHidden(true)

                    Text("FaceFX Kit")
                        .font(.system(size: 28, weight: .semibold))
                        .tracking(-0.56)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                }

                PhotosPicker(
                    selection: $imageSelection,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 10) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(Color.onAccent)
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text("Select Photo")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Color.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accent, in: .rect(cornerRadius: 16))
                }
                .buttonStyle(.pressable)
                .disabled(viewModel.isLoading)
                .onChange(of: imageSelection) { _, newValue in
                    guard let newValue else { return }

                    Task {
                        await viewModel.selectPhotoFromGallery(item: newValue)
                        imageSelection = nil
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $viewModel.showingEditor) {
                if let photo = viewModel.selectedPhoto {
                    EditorView(
                        photo: photo,
                        applicationService: dependencies.photoEditorApplicationService,
                        ciContext: dependencies.ciContextStore.primaryContext
                    )
                        .id(photo.id)
                }
            }
            .errorAlert(message: $viewModel.errorMessage)
        }
    }
}
