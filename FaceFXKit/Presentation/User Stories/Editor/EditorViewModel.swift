//
//  EditorViewModel.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import SwiftUI

@MainActor
@Observable
final class EditorViewModel {
    var photo: Photo?
    var selectedCategory: FilterCategory?
    var isShowingFilters = false
    var selectedGroupFilter: FilterGroup?
    var isShowingIndividualFilters = false
    var selectedFilterConfiguration: FilterConfiguration?
    var isFaceDetecting = false
    var showLandmarks = false
    var showHairMask = false
    var errorMessage: String?
    var zoomPan = ImageZoomPanModel()

    var cachedDetectionData: DetectionData?

    /// The image the Metal preview draws. Computed from `photo`, so every
    /// committed filter render publishes a new preview automatically.
    var previewImage: CIImage? {
        photo?.currentImage
    }

    var availableGroupFilters: [FilterGroup] {
        selectedCategory?.groups ?? []
    }

    var availableIndividualFilters: [FilterType] {
        selectedGroupFilter?.filterTypes ?? []
    }

    private let applicationService: PhotoEditorApplicationService
    private let transitionAnimation = Animation.easeInOut(duration: 0.3)

    @ObservationIgnored private var filterUpdateTask: Task<Void, Never>?
    @ObservationIgnored private var detectionTask: Task<Void, Never>?
    @ObservationIgnored private var pendingConfiguration: FilterConfiguration?

    init(photo: Photo?, applicationService: PhotoEditorApplicationService) {
        self.photo = photo
        self.applicationService = applicationService
    }

    /// Cancels any in-flight work when the editor goes away.
    func cancelPendingWork() {
        cancelRendering()
        detectionTask?.cancel()
    }

    // MARK: - Filters

    /// Applies a new slider intensity. Renders go through a single coalescing
    /// loop: every completed render commits immediately (live preview while
    /// dragging), values that arrive mid-render replace the pending one instead
    /// of queueing, and because renders are serialized a stale result can never
    /// overwrite a newer one.
    func setFilterIntensity(_ intensity: Float) {
        selectedFilterConfiguration?.updateFilter(intensity: intensity)
        guard let configuration = selectedFilterConfiguration else { return }

        pendingConfiguration = configuration
        startRenderLoopIfNeeded()
    }

    private func startRenderLoopIfNeeded() {
        guard filterUpdateTask == nil else { return }

        filterUpdateTask = Task {
            while !Task.isCancelled, let configuration = pendingConfiguration {
                pendingConfiguration = nil
                await updateFilter(configuration: configuration)
            }
            // A cancelled loop must not clear the slot — a fresh loop may
            // already own it.
            if !Task.isCancelled {
                filterUpdateTask = nil
            }
        }
    }

    private func cancelRendering() {
        pendingConfiguration = nil
        filterUpdateTask?.cancel()
        filterUpdateTask = nil
    }

    private func updateFilter(configuration: FilterConfiguration) async {
        guard let photo, let selectedCategory else { return }

        errorMessage = nil

        do {
            let processedPhoto = try await applicationService.applyFilters(
                to: photo,
                configuration: configuration,
                detectionData: detectionData(for: selectedCategory)
            )

            guard !Task.isCancelled else { return }
            self.photo = processedPhoto
        } catch is CancellationError {
            // Superseded by a newer intensity value — drop the stale result.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func selectCategory(_ category: FilterCategory) {
        selectedCategory = category

        // Every category requires detection data (face landmarks or hair mask).
        withAnimation(transitionAnimation) {
            isFaceDetecting = true
        }

        detectionTask?.cancel()
        detectionTask = Task {
            await detectDataIfNeeded()
            guard !Task.isCancelled else { return }

            withAnimation(transitionAnimation) {
                isFaceDetecting = false
                isShowingFilters = true
                isShowingIndividualFilters = false
                selectedGroupFilter = nil
                selectedFilterConfiguration = nil
            }
        }
    }

    private func detectionData(for category: FilterCategory) -> DetectionData? {
        cachedDetectionData?.categories.contains(category) == true ? cachedDetectionData : nil
    }

    private func detectDataIfNeeded() async {
        guard let photo, let selectedCategory, detectionData(for: selectedCategory) == nil else { return }

        errorMessage = nil

        do {
            let detectionData = try await applicationService.detectData(in: photo.originalImage, for: selectedCategory)
            guard !Task.isCancelled else { return }
            cachedDetectionData = detectionData
        } catch is CancellationError {
            // The editor was dismissed or the category changed mid-detection.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = "Failed to detect data: \(error.localizedDescription)"
        }
    }

    func selectGroupFilter(_ filterGroup: FilterGroup) {
        selectedGroupFilter = filterGroup
        if let firstFilter = availableIndividualFilters.first {
            selectIndividualFilter(firstFilter)
        }

        withAnimation(transitionAnimation) {
            isShowingIndividualFilters = true
        }
    }

    func selectIndividualFilter(_ filterType: FilterType) {
        selectedFilterConfiguration = FilterConfiguration(filter: filterType, intensity: 0)
    }

    func backToGroupFilters() {
        withAnimation(transitionAnimation) {
            isShowingIndividualFilters = false
            selectedFilterConfiguration = nil
        }
    }

    func backToCategories() {
        withAnimation(transitionAnimation) {
            isShowingFilters = false
            isShowingIndividualFilters = false
            selectedCategory = nil
            selectedGroupFilter = nil
            selectedFilterConfiguration = nil
        }
    }

    func resetAllFilters() {
        guard var photo else { return }

        errorMessage = nil
        cancelRendering()

        if let filter = selectedFilterConfiguration?.filter {
            selectIndividualFilter(filter)
        }

        photo.updateProcessedImage(photo.originalImage)
        self.photo = photo
    }

    func savePhoto() async -> Bool {
        guard let photo else { return false }

        do {
            try await applicationService.savePhoto(photo)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggleLandmarks() {
        showLandmarks.toggle()
    }

    func toggleHairMask() {
        showHairMask.toggle()
    }

    // MARK: - Zoom & Pan

    func resetZoom() {
        withAnimation(.spring()) {
            zoomPan.reset()
        }
    }

    func updateScale(_ scale: CGFloat, in containerSize: CGSize) {
        guard let imageSize = previewImage?.extent.size else { return }
        zoomPan.updateScale(scale, imagePixelSize: imageSize, containerSize: containerSize)
    }

    func finalizeScale() {
        if zoomPan.scale < 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                zoomPan.finalizeScale()
            }
        } else {
            zoomPan.finalizeScale()
        }
    }

    func updateOffset(_ translation: CGSize, in containerSize: CGSize) {
        guard let imageSize = previewImage?.extent.size else { return }
        zoomPan.updateOffset(translation: translation, imagePixelSize: imageSize, containerSize: containerSize)
    }

    func finalizeOffset() {
        zoomPan.finalizeOffset()
    }
}
