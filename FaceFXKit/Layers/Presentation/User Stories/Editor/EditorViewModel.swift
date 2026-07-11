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

    private let applicationService: PhotoEditorApplicationService

    @ObservationIgnored private var filterUpdateTask: Task<Void, Never>?
    @ObservationIgnored private var detectionTask: Task<Void, Never>?
    @ObservationIgnored private var pendingConfiguration: FilterConfiguration?

    init(
        photo: Photo?,
        applicationService: PhotoEditorApplicationService
    ) {
        self.photo = photo
        self.applicationService = applicationService
    }

    /// Cancels any in-flight work when the editor goes away.
    func cancelPendingWork() {
        pendingConfiguration = nil
        filterUpdateTask?.cancel()
        filterUpdateTask = nil
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

    func updateFilter(configuration: FilterConfiguration) async {
        guard let photo, let selectedCategory else { return }

        errorMessage = nil

        do {
            let detectionDataToUse = cachedDetectionData?.categories.contains(selectedCategory) == true ? cachedDetectionData : nil

            let processedPhoto = try await applicationService.applyFilters(
                to: photo,
                configuration: configuration,
                detectionData: detectionDataToUse
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
        withAnimation(.easeInOut(duration: 0.3)) {
            isFaceDetecting = true
        }
        detectionTask?.cancel()
        detectionTask = Task {
            await detectDataIfNeeded()
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                isFaceDetecting = false
                isShowingFilters = true
                isShowingIndividualFilters = false
                selectedGroupFilter = nil
                selectedFilterConfiguration = nil
            }
        }
    }

    private func detectDataIfNeeded() async {
        guard let photo, let selectedCategory else { return }
        guard cachedDetectionData?.categories.contains(selectedCategory) != true else { return }

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
            selectedFilterConfiguration = FilterConfiguration(filter: firstFilter, intensity: 0.0)
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingIndividualFilters = true
        }
    }

    func selectIndividualFilter(_ filterType: FilterType) {
        selectedFilterConfiguration = FilterConfiguration(filter: filterType, intensity: 0.0)
    }

    func backToGroupFilters() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingIndividualFilters = false
            selectedFilterConfiguration = nil
        }
    }

    func backToCategories() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingFilters = false
            isShowingIndividualFilters = false
            selectedCategory = nil
            selectedGroupFilter = nil
            selectedFilterConfiguration = nil
        }
    }

    var availableGroupFilters: [FilterGroup] {
        guard let category = selectedCategory else { return [] }
        return category.groups
    }

    var availableIndividualFilters: [FilterType] {
        guard let groupFilter = selectedGroupFilter else { return [] }
        return groupFilter.filterTypes
    }

    func resetAllFilters() {
        guard var photo else { return }

        errorMessage = nil
        pendingConfiguration = nil
        filterUpdateTask?.cancel()
        filterUpdateTask = nil

        if let selectedFilterConfiguration {
            self.selectedFilterConfiguration = FilterConfiguration(
                filter: selectedFilterConfiguration.filter,
                intensity: 0.0
            )
        }
        photo.updateProcessedImage(photo.originalImage)
        self.photo = photo
    }

    func savePhoto() async {
        guard let photo else { return }

        do {
            try await applicationService.savePhoto(photo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
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
        guard let imagePixelSize = currentImagePixelSize else { return }
        zoomPan.updateScale(scale, imagePixelSize: imagePixelSize, containerSize: containerSize)
    }

    func finalizeScale() {
        if zoomPan.scale < 1.0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                _ = zoomPan.finalizeScale()
            }
        } else {
            _ = zoomPan.finalizeScale()
        }
    }

    func updateOffset(_ translation: CGSize, in containerSize: CGSize) {
        guard let imagePixelSize = currentImagePixelSize else { return }
        zoomPan.updateOffset(translation: translation, imagePixelSize: imagePixelSize, containerSize: containerSize)
    }

    func finalizeOffset() {
        zoomPan.finalizeOffset()
    }

    private var currentImagePixelSize: CGSize? {
        guard let previewImage else { return nil }
        return previewImage.extent.size
    }
}
