//
//  SavedConfirmationSheet.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 17/10/2026.
//

import SwiftUI

struct SavedConfirmationSheet: View {
    let appliedEdits: [String]
    let keepEditing: () -> Void
    let newPhoto: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.scrim
                .ignoresSafeArea()
                .onTapGesture(perform: keepEditing)
                .transition(.opacity)

            sheet
                .transition(.move(edge: .bottom))
        }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.sheetGrabber)
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)

            HStack(spacing: 14) {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.onAccent)
                    .frame(width: 48, height: 48)
                    .background(Color.accent, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved to Photos")
                        .font(.system(size: 20, weight: .semibold))
                        .tracking(-0.2)
                    Text("A copy of your edit is in your library.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(appliedEdits.isEmpty ? ["No changes"] : appliedEdits, id: \.self) { edit in
                    Text(edit)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.pillText)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Color.tag, in: .capsule)
                }
            }

            HStack(spacing: 10) {
                Button(action: keepEditing) {
                    Text("Keep Editing")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.border, lineWidth: 1)
                        }
                        .contentShape(.rect)
                }

                Button(action: newPhoto) {
                    Text("New Photo")
                        .foregroundStyle(Color.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accent, in: .rect(cornerRadius: 16))
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .buttonStyle(.pressable)
        }
        .padding(.top, 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(Color.sheet)
                .ignoresSafeArea(edges: .bottom)
        }
        .accessibilityAddTraits(.isModal)
    }
}
