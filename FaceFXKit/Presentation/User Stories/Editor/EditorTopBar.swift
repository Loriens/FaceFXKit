//
//  EditorTopBar.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

struct EditorTopBar: View {
    let viewModel: EditorViewModel
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 44, height: 44)
                    .contentShape(.circle)
            }
            .accessibilityLabel("Close")

            Spacer(minLength: 0)

            if viewModel.panelLevel != .categories {
                overlayToggle
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            saveButton
        }
        .buttonStyle(.pressable)
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .frame(height: 44)
    }

    private var overlayToggle: some View {
        let isOn = viewModel.isOverlayVisible
        let title = switch viewModel.selectedCategory {
        case .hair: isOn ? "Hide Hair" : "Show Hair"
        case .sizes: isOn ? "Hide Points" : "Show Points"
        }
        let isAvailable = viewModel.currentDetectionData != nil

        return Button(action: viewModel.toggleOverlay) {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isOn ? Color.accent : Color.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isOn ? Color.accent.opacity(0.14) : .clear, in: .capsule)
            .overlay {
                Capsule().strokeBorder(isOn ? Color.accent : Color.border, lineWidth: 1)
            }
        }
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.4)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.savePhoto()
            }
        } label: {
            Text("Save")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.onAccent)
                .padding(.horizontal, 18)
                .frame(height: 36)
                .background(Color.accent, in: .capsule)
        }
        .disabled(viewModel.isSaving)
        .opacity(viewModel.isSaving ? 0.6 : 1)
    }
}
