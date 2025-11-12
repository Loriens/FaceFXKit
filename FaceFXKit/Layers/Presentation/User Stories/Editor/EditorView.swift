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

    init(photo: Photo?) {
        let applicationService = DIContainer.shared.photoEditorApplicationService
        self.viewModel = EditorViewModel(photo: photo, applicationService: applicationService)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    Color(.systemBackground)

                    if let image = viewModel.currentImage {
                        ZStack {
                            Image(image, scale: 1.0, label: Text("Photo"))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(viewModel.imageScale)
                                .offset(viewModel.imageOffset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let newScale = viewModel.lastScale * value
                                                viewModel.updateScale(newScale, in: geometry.size)
                                            }
                                            .onEnded { value in
                                                let newScale = viewModel.lastScale * value
                                                viewModel.updateScale(newScale, in: geometry.size)
                                                viewModel.finalizeScale()
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                viewModel.updateOffset(value.translation, in: geometry.size)
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
                                            imageSize: viewModel.currentCIImage?.extent.size ?? .zero,
                                            imageScale: viewModel.imageScale,
                                            imageOffset: viewModel.imageOffset
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
                                            imageSize: viewModel.currentCIImage?.extent.size ?? .zero,
                                            imageScale: viewModel.imageScale,
                                            imageOffset: viewModel.imageOffset
                                        )
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                }
                        }
                    }

                    if viewModel.isFaceDetecting {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)

                            let detectionMessage = viewModel.selectedCategory == .hair
                                ? "Analyzing hair..."
                                : "Detecting faces..."
                            Text(detectionMessage)
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }

                    VStack {
                        Spacer()

                        VStack(spacing: 16) {
                            if !viewModel.isShowingFilters, !viewModel.isFaceDetecting {
                                HStack {
                                    ForEach(FilterCategory.allCases, id: \.self) { category in
                                        Button(category.rawValue) {
                                            viewModel.selectCategory(category)
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else if !viewModel.isShowingIndividualFilters {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.availableGroupFilters, id: \.self) { groupFilter in
                                            Button(groupFilter.rawValue) {
                                                viewModel.selectGroupFilter(groupFilter)
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else {
                                VStack(spacing: 16) {
                                    Text(viewModel.selectedCategory?.rawValue ?? "")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.black.opacity(0.7))
                                        )
                                        .padding(.horizontal)

                                    if let configuration = viewModel.selectedFilterConfiguration {
                                        DualModeSlider(
                                            value: Binding(
                                                get: { Double(configuration.intensity) },
                                                set: { intensity in
                                                    viewModel
                                                        .selectedFilterConfiguration?
                                                        .updateFilter(intensity: Float(intensity))

                                                    Task {
                                                        await viewModel.updateFilterIntensity(Float(intensity))
                                                    }
                                                }
                                            ),
                                            mode: configuration.filter == .headSize ? .bipolar : .unipolar,
                                            step: 0.01,
                                            trackHeight: 8,
                                            thumbSize: 28,
                                            snapToZeroDeadband: 0.05
                                        )
                                        .frame(maxWidth: .infinity)
                                        .frame(width: UIScreen.main.bounds.width * 0.7, height: 40)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.7))
                                        )
                                        .padding(.horizontal)
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(viewModel.availableIndividualFilters, id: \.self) { filterType in
                                                Button(filterType.displayName) {
                                                    viewModel.selectIndividualFilter(filterType)
                                                }
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    viewModel.selectedFilterConfiguration?.filter == filterType
                                                        ? Color.blue
                                                        : Color.black.opacity(0.6)
                                                )
                                                .cornerRadius(8)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.bottom, 10)
                    }
                }
                .clipped()
            }

            VStack {
                HStack {
                    Button(viewModel.isShowingFilters ? "Back" : "Close") {
                        if viewModel.isShowingIndividualFilters {
                            viewModel.backToGroupFilters()
                        } else if viewModel.isShowingFilters {
                            viewModel.backToCategories()
                        } else {
                            dismiss()
                        }

                        Task {
                            await viewModel.resetAllFilters()
                        }
                    }
                    .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 8) {
                        if viewModel.cachedDetectionData?.faceTrackingResult != nil {
                            Button(viewModel.showLandmarks ? "Hide Points" : "Show Points") {
                                viewModel.toggleLandmarks()
                            }
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                        
                        if viewModel.cachedDetectionData?.hairSegmentationResult != nil {
                            Button(viewModel.showHairMask ? "Hide Hair" : "Show Hair") {
                                viewModel.toggleHairMask()
                            }
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                    }

                    Button("Save") {
                        Task {
                            await viewModel.savePhoto()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Color(.systemBackground)
                )

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
