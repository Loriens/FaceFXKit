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
    var photo: Photo? {
        didSet {
            if let ciImage = photo?.processedImage ?? photo?.currentImage {
                self.currentImage = ciContextStore.createCGImage(from: ciImage)
            }
        }
    }
    var selectedCategory: FilterCategory?
    var isShowingFilters = false
    var selectedGroupFilter: FilterGroup?
    var isShowingIndividualFilters = false
    var selectedFilterConfiguration: FilterConfiguration?
    var isFaceDetecting = false
    var showLandmarks = false
    var showHairMask = false
    var errorMessage: String?
    var imageScale: CGFloat = 1.0
    var imageOffset: CGSize = .zero
    var lastScale: CGFloat = 1.0
    var lastOffset: CGSize = .zero

    var cachedDetectionData: DetectionData?
    private let applicationService: PhotoEditorApplicationService
    private let ciContextStore: CIContextStore

    var currentImage: CGImage?
    
    var currentCIImage: CIImage? {
        photo?.currentImage
    }

    init(
        photo: Photo?,
        applicationService: PhotoEditorApplicationService
    ) {
        self.photo = photo
        self.applicationService = applicationService
        self.ciContextStore = DIContainer.shared.ciContextStore

        if let ciImage = photo?.currentImage {
            self.currentImage = ciContextStore.createCGImage(from: ciImage)
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
            self.photo = processedPhoto
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCategory(_ category: FilterCategory) {
        selectedCategory = category

        // For categories that require detection, we need to detect first
        if category == .sizes || category == .hair {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFaceDetecting = true
            }
            Task {
                await detectDataIfNeeded()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFaceDetecting = false
                        isShowingFilters = true
                        isShowingIndividualFilters = false
                        selectedGroupFilter = nil
                        selectedFilterConfiguration = nil
                    }
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowingFilters = true
                isShowingIndividualFilters = false
                selectedGroupFilter = nil
                selectedFilterConfiguration = nil
            }
        }
    }

    private func detectDataIfNeeded() async {
        guard let photo, let selectedCategory else { return }

        await MainActor.run {
            errorMessage = nil
        }

        do {
            let detectionData = try await applicationService.detectData(in: photo.originalImage, for: selectedCategory)
            await MainActor.run {
                cachedDetectionData = detectionData
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to detect data: \(error.localizedDescription)"
            }
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

    func updateFilterIntensity(_ intensity: Float) async {
        guard let selectedFilterConfiguration else { return }
        await updateFilter(configuration: selectedFilterConfiguration)
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

    func resetZoom() {
        withAnimation(.spring()) {
            imageScale = 1.0
            imageOffset = .zero
            lastScale = 1.0
            lastOffset = .zero
        }
    }

    func updateScale(_ scale: CGFloat, in containerSize: CGSize) {
        imageScale = max(0.7, min(scale, 5.0))
        constrainOffset(in: containerSize)
    }

    func finalizeScale() {
        let constrainedScale = max(1.0, min(imageScale, 5.0))

        if imageScale < 1.0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                imageScale = constrainedScale
                imageOffset = .zero
            }
        }

        lastScale = constrainedScale
        lastOffset = imageOffset
    }

    func constrainOffset(in containerSize: CGSize) {
        guard let image = currentImage else { return }

        let imageSize = calculateImageSize(image, in: containerSize)
        let scaledImageSize = CGSize(
            width: imageSize.width * imageScale,
            height: imageSize.height * imageScale
        )

        if imageScale < 1.0 {
            imageOffset = .zero
            return
        }

        let maxOffsetX = max(0, (scaledImageSize.width - containerSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageSize.height - containerSize.height) / 2)

        imageOffset = CGSize(
            width: max(-maxOffsetX, min(maxOffsetX, imageOffset.width)),
            height: max(-maxOffsetY, min(maxOffsetY, imageOffset.height))
        )
    }

    func updateOffset(_ translation: CGSize, in containerSize: CGSize) {
        guard let image = currentImage else { return }

        if imageScale < 1.0 {
            imageOffset = .zero
            return
        }

        let imageSize = calculateImageSize(image, in: containerSize)
        let scaledImageSize = CGSize(
            width: imageSize.width * imageScale,
            height: imageSize.height * imageScale
        )

        let maxOffsetX = max(0, (scaledImageSize.width - containerSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageSize.height - containerSize.height) / 2)

        let newOffset = CGSize(
            width: lastOffset.width + translation.width,
            height: lastOffset.height + translation.height
        )

        imageOffset = CGSize(
            width: max(-maxOffsetX, min(maxOffsetX, newOffset.width)),
            height: max(-maxOffsetY, min(maxOffsetY, newOffset.height))
        )
    }

    func finalizeOffset() {
        lastOffset = imageOffset
    }

    func resetAllFilters() async {
        guard var photo else { return }

        errorMessage = nil

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

    private func calculateImageSize(_ image: CGImage, in containerSize: CGSize) -> CGSize {
        let imageAspectRatio = CGFloat(image.width) / CGFloat(image.height)
        let containerAspectRatio = containerSize.width / containerSize.height

        if imageAspectRatio > containerAspectRatio {
            // Image is wider than container
            let height = containerSize.width / imageAspectRatio
            return CGSize(width: containerSize.width, height: height)
        } else {
            // Image is taller than container
            let width = containerSize.height * imageAspectRatio
            return CGSize(width: width, height: containerSize.height)
        }
    }
}
