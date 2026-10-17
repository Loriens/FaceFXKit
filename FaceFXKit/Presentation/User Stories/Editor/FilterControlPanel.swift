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
        VStack(spacing: 16) {
            Group {
                if !viewModel.isShowingFilters, !viewModel.isFaceDetecting {
                    categoryButtons
                } else if !viewModel.isShowingIndividualFilters {
                    groupFilterButtons
                } else {
                    individualFilterControls
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
                .background(.blue, in: .rect(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }

    private var groupFilterButtons: some View {
        filterRow(viewModel.availableGroupFilters, title: \.rawValue) {
            viewModel.selectGroupFilter($0)
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
                .background(.black.opacity(0.7), in: .rect(cornerRadius: 8))
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
                .background(.black.opacity(0.7), in: .rect(cornerRadius: 12))
                .padding(.horizontal)
            }

            filterRow(
                viewModel.availableIndividualFilters,
                title: \.displayName,
                isSelected: { viewModel.selectedFilterConfiguration?.filter == $0 }
            ) {
                viewModel.selectIndividualFilter($0)
            }
        }
    }

    private func filterRow<Item: Hashable>(
        _ items: [Item],
        title: KeyPath<Item, String>,
        isSelected: @escaping (Item) -> Bool = { _ in true },
        action: @escaping (Item) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items, id: \.self) { item in
                    Button(item[keyPath: title]) {
                        action(item)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isSelected(item) ? Color.blue : Color.black.opacity(0.6), in: .rect(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
    }
}
