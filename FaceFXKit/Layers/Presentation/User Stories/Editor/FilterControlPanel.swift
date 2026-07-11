//
//  FilterControlPanel.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

/// Bottom control area: category buttons, filter-group row, and the individual
/// filter row with its intensity slider.
struct FilterControlPanel: View {
    let viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 16) {
            if !viewModel.isShowingFilters, !viewModel.isFaceDetecting {
                categoryButtons
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if !viewModel.isShowingIndividualFilters {
                groupFilterButtons
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                individualFilterControls
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.vertical, 20)
        .padding(.bottom, 10)
    }

    private var categoryButtons: some View {
        HStack {
            ForEach(FilterCategory.allCases, id: \.self) { category in
                Button(category.rawValue) {
                    viewModel.selectCategory(category)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }

    private var groupFilterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.availableGroupFilters, id: \.self) { groupFilter in
                    Button(groupFilter.rawValue) {
                        viewModel.selectGroupFilter(groupFilter)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(.rect(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
    }

    private var individualFilterControls: some View {
        VStack(spacing: 16) {
            Text(viewModel.selectedCategory?.rawValue ?? "")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.7))
                )
                .padding(.horizontal)

            if let configuration = viewModel.selectedFilterConfiguration {
                FilterIntensitySlider(
                    value: Binding(
                        get: { Double(configuration.intensity) },
                        set: { viewModel.setFilterIntensity(Float($0)) }
                    ),
                    mode: configuration.filter.preferredSliderMode
                )
                .frame(height: 40)
                .containerRelativeFrame(.horizontal) { length, _ in
                    length * 0.7
                }
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
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedFilterConfiguration?.filter == filterType
                                ? Color.blue
                                : Color.black.opacity(0.6)
                        )
                        .clipShape(.rect(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
