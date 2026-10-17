//
//  FilterControlPanel.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

struct FilterControlPanel: View {
    let viewModel: EditorViewModel

    var body: some View {
        ZStack(alignment: .top) {
            switch viewModel.panelLevel {
            case .categories:
                categoryLevel
                    .transition(.opacity)
            case .groups:
                groupLevel
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .adjustments:
                adjustmentLevel
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.horizontal, 16)
        .clipped()
        .buttonStyle(.pressable)
        .disabled(viewModel.isDetecting)
        .opacity(viewModel.isDetecting ? 0.35 : 1)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isDetecting)
    }

    private var categoryLevel: some View {
        HStack(spacing: 10) {
            ForEach(FilterCategory.allCases, id: \.self) { category in
                Button {
                    viewModel.selectCategory(category)
                } label: {
                    Label(category.rawValue, systemImage: category.symbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.surface, in: .rect(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14).strokeBorder(Color.border, lineWidth: 1)
                        }
                        .contentShape(.rect(cornerRadius: 14))
                }
            }
        }
    }

    private var groupLevel: some View {
        HStack(spacing: 4) {
            backButton

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedCategory.groups, id: \.self) { group in
                        groupChip(group)
                    }
                }
                .padding(.trailing, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.trailing, -16)
        }
        .frame(height: 44)
    }

    private func groupChip(_ group: FilterGroup) -> some View {
        Button {
            viewModel.selectGroup(group)
        } label: {
            HStack(spacing: 7) {
                Text(group.rawValue)
                editedDot(isVisible: viewModel.isEdited(group), color: .accent)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.chipText)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .overlay {
                Capsule().strokeBorder(Color.border, lineWidth: 1)
            }
            .contentShape(.capsule)
        }
    }

    private var adjustmentLevel: some View {
        let filter = viewModel.activeFilter
        let intensity = filter.map(viewModel.intensity(of:)) ?? 0

        return VStack(spacing: 8) {
            HStack(spacing: 2) {
                backButton

                Text(viewModel.selectedGroup?.rawValue ?? "")
                    .font(.system(size: 17, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 0)

                Text(filter?.formattedIntensity(intensity) ?? "—")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.accent)
                    .frame(minWidth: 44, alignment: .trailing)

                Button(action: viewModel.resetActiveFilter) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .accessibilityLabel("Reset filter")
            }
            .frame(height: 44)

            if viewModel.selectedGroup == .hairColors {
                hairColorSwatches
            } else {
                filterPills
            }

            FilterIntensitySlider(
                value: Binding(
                    get: { Double(intensity) },
                    set: { viewModel.setActiveFilterIntensity(Float($0)) }
                ),
                mode: filter?.preferredSliderMode ?? .unipolar
            )
            .frame(height: 28)
            .padding(.horizontal, 12)
            .disabled(filter == nil)
        }
    }

    private var hairColorSwatches: some View {
        edgeToEdgeScroll(spacing: 4, inset: 12) {
            swatch(for: nil)
            ForEach(FilterGroup.hairColors.filterTypes, id: \.self) { filter in
                swatch(for: filter)
            }
        }
        .frame(height: 68)
    }

    private func swatch(for filter: FilterType?) -> some View {
        let isSelected = filter == viewModel.selectedHairColor

        return Button {
            viewModel.selectHairColor(filter)
        } label: {
            VStack(spacing: 8) {
                Group {
                    if let color = filter?.swatchColor {
                        Circle().fill(color)
                    } else {
                        Circle()
                            .fill(Color.surfaceRaised)
                            .overlay {
                                Image(systemName: "nosign")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.textSecondary)
                            }
                    }
                }
                .frame(width: 40, height: 40)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.accent, lineWidth: 2)
                            .padding(-4)
                    } else {
                        Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1)
                    }
                }

                Text(filter?.hairColorName ?? "Original")
                    .font(.system(size: 11, weight: .medium))
                    .fixedSize()
                    .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            }
            .frame(width: 62)
            .padding(.vertical, 4)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var filterPills: some View {
        edgeToEdgeScroll(spacing: 8, inset: 16) {
            ForEach(viewModel.selectedGroup?.filterTypes ?? [], id: \.self) { filter in
                let isSelected = filter == viewModel.activeFilter

                Button {
                    viewModel.selectFilter(filter)
                } label: {
                    HStack(spacing: 8) {
                        Text(filter.displayName)
                        editedDot(
                            isVisible: viewModel.intensity(of: filter) != 0,
                            color: isSelected ? .onAccent : .accent
                        )
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.onAccent : Color.pillText)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(isSelected ? Color.accent : Color.surfaceRaised, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected ? Color.accent : Color.track, lineWidth: 1)
                    }
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var backButton: some View {
        Button(action: viewModel.goBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .accessibilityLabel("Back")
        .padding(.leading, -14)
    }

    private func editedDot(isVisible: Bool, color: Color) -> some View {
        Circle()
            .fill(isVisible ? color : .clear)
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
    }

    private func edgeToEdgeScroll<Content: View>(
        spacing: CGFloat,
        inset: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) {
                content()
            }
            .padding(.horizontal, inset)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -16)
    }
}

private extension FilterCategory {
    var symbolName: String {
        switch self {
        case .sizes: "arrow.up.left.and.arrow.down.right"
        case .hair: "paintbrush.pointed"
        }
    }
}
