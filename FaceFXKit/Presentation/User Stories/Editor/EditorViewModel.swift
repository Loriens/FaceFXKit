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
    enum PanelLevel {
        case categories
        case groups
        case adjustments
    }

    private(set) var photo: Photo
    private(set) var panelLevel: PanelLevel = .categories
    private(set) var selectedCategory: FilterCategory = .hair
    private(set) var intensities: [FilterType: Float] = [:]
    private(set) var selectedGroup: FilterGroup?
    private(set) var selectedHairColor: FilterType?
    private(set) var detectionCache: [FilterCategory: DetectionData] = [:]
    private(set) var isSaving = false
    var isComparing = false
    var isShowingSavedConfirmation = false
    var showLandmarks = false
    var showHairMask = false
    var errorMessage: String?
    var zoomPan = ImageZoomPanModel()

    private var selectedFilters: [FilterGroup: FilterType] = [:]
    private var detectingCategories: Set<FilterCategory> = []

    private let applicationService: PhotoEditorApplicationService
    private let transitionAnimation = Animation.easeInOut(duration: 0.3)
    private static let defaultHairColorIntensity: Float = 0.8

    @ObservationIgnored private var renderTask: Task<Void, Never>?
    @ObservationIgnored private var needsRender = false
    @ObservationIgnored private var detectionTasks: [FilterCategory: Task<Void, Never>] = [:]

    init(photo: Photo, applicationService: PhotoEditorApplicationService) {
        self.photo = photo
        self.applicationService = applicationService
    }

    func cancelPendingWork() {
        needsRender = false
        renderTask?.cancel()
        renderTask = nil
        detectionTasks.values.forEach { $0.cancel() }
        detectionTasks.removeAll()
        detectingCategories.removeAll()
    }

    var previewImage: CIImage {
        isComparing ? photo.originalImage : photo.currentImage
    }

    var isDetecting: Bool {
        detectingCategories.contains(selectedCategory)
    }

    var currentDetectionData: DetectionData? {
        detectionCache[selectedCategory]
    }

    var activeFilter: FilterType? {
        guard let group = selectedGroup else { return nil }
        if group == .hairColors {
            return selectedHairColor
        }
        return selectedFilters[group] ?? group.filterTypes.first
    }

    var isOverlayVisible: Bool {
        selectedCategory == .hair ? showHairMask : showLandmarks
    }

    func intensity(of filter: FilterType) -> Float {
        intensities[filter] ?? 0
    }

    func isEdited(_ group: FilterGroup) -> Bool {
        if group == .hairColors {
            return selectedHairColor != nil
        }
        return group.filterTypes.contains { intensity(of: $0) != 0 }
    }

    var appliedConfigurations: [FilterConfiguration] {
        [FilterCategory.hair, .sizes]
            .flatMap(\.groups)
            .flatMap(\.filterTypes)
            .compactMap { filter in
                if filter.group == .hairColors, filter != selectedHairColor {
                    return nil
                }
                let intensity = intensity(of: filter)
                return intensity == 0 ? nil : FilterConfiguration(filter: filter, intensity: intensity)
            }
    }

    func selectCategory(_ category: FilterCategory) {
        selectedCategory = category
        isComparing = false

        if detectionCache[category] != nil {
            showLevel(.groups)
        } else if !detectingCategories.contains(category) {
            detect(category)
        }
    }

    func selectGroup(_ group: FilterGroup) {
        selectedGroup = group
        showLevel(.adjustments)
    }

    func goBack() {
        switch panelLevel {
        case .categories:
            break
        case .groups:
            showLevel(.categories)
        case .adjustments:
            showLevel(.groups)
        }
    }

    private func showLevel(_ level: PanelLevel) {
        withAnimation(transitionAnimation) {
            panelLevel = level
        }
    }

    func selectFilter(_ filter: FilterType) {
        selectedFilters[filter.group] = filter
    }

    func selectHairColor(_ filter: FilterType?) {
        selectedHairColor = filter
        if let filter, intensities[filter] == nil {
            intensities[filter] = Self.defaultHairColorIntensity
        }
        scheduleRender()
    }

    func setActiveFilterIntensity(_ intensity: Float) {
        guard let filter = activeFilter else { return }
        intensities[filter] = intensity
        scheduleRender()
    }

    func resetActiveFilter() {
        guard let filter = activeFilter else { return }

        if filter.group == .hairColors {
            intensities[filter] = nil
            selectHairColor(nil)
        } else {
            intensities[filter] = 0
            scheduleRender()
        }
    }

    private func scheduleRender() {
        needsRender = true
        guard renderTask == nil else { return }

        renderTask = Task {
            while !Task.isCancelled, needsRender {
                needsRender = false
                await render()
            }
            if !Task.isCancelled {
                renderTask = nil
            }
        }
    }

    private func render() async {
        do {
            let processedPhoto = try await applicationService.applyFilters(
                to: photo,
                configurations: appliedConfigurations,
                detectionData: detectionCache
            )

            guard !Task.isCancelled else { return }
            photo = processedPhoto
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func detect(_ category: FilterCategory) {
        withAnimation(transitionAnimation) {
            _ = detectingCategories.insert(category)
        }

        detectionTasks[category] = Task {
            defer {
                detectionTasks[category] = nil
                withAnimation(transitionAnimation) {
                    _ = detectingCategories.remove(category)
                }
            }

            do {
                let detectionData = try await applicationService.detectData(in: photo.originalImage, for: category)
                guard !Task.isCancelled else { return }
                detectionCache[category] = detectionData
                if selectedCategory == category, panelLevel == .categories {
                    showLevel(.groups)
                }
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Failed to detect data: \(error.localizedDescription)"
            }
        }
    }

    func toggleOverlay() {
        if selectedCategory == .hair {
            showHairMask.toggle()
        } else {
            showLandmarks.toggle()
        }
    }

    func toggleCompare() {
        isComparing.toggle()
    }

    func savePhoto() async {
        isSaving = true
        isComparing = false
        defer { isSaving = false }

        await renderTask?.value

        do {
            try await applicationService.savePhoto(photo)
            withAnimation(transitionAnimation) {
                isShowingSavedConfirmation = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissSavedConfirmation() {
        withAnimation(transitionAnimation) {
            isShowingSavedConfirmation = false
        }
    }

    func resetZoom() {
        withAnimation(.spring()) {
            zoomPan.reset()
        }
    }

    func updateScale(_ scale: CGFloat, in containerSize: CGSize) {
        zoomPan.updateScale(scale, imagePixelSize: previewImage.extent.size, containerSize: containerSize)
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
        zoomPan.updateOffset(translation: translation, imagePixelSize: previewImage.extent.size, containerSize: containerSize)
    }

    func finalizeOffset() {
        zoomPan.finalizeOffset()
    }
}
