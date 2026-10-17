//
//  AnalyzingOverlay.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 17/10/2026.
//

import SwiftUI

struct AnalyzingOverlay: View {
    let category: FilterCategory

    @State private var isScanning = false

    private static let scanBandHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack(alignment: .top) {
                Color.appBackground.opacity(0.45)

                ViewfinderBrackets()
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: size.width * 0.44, height: size.height * 0.46)
                    .position(x: size.width / 2, y: size.height * 0.405)

                scanLine
                    .offset(y: isScanning ? size.height : -Self.scanBandHeight)
            }
        }
        .overlay(alignment: .bottom) {
            statusPill
                .padding(.bottom, 24)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: true)) {
                isScanning = true
            }
        }
    }

    private var scanLine: some View {
        VStack(spacing: 0) {
            Color.accent.opacity(0.12)
                .frame(height: Self.scanBandHeight)
            Color.accent
                .frame(height: 2)
        }
        .accessibilityHidden(true)
    }

    private var statusPill: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(Color.accent)
            Text(category == .hair ? "Analyzing hair…" : "Detecting faces…")
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(Color.appBackground.opacity(0.8), in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

private struct ViewfinderBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = min(rect.width, rect.height) * 0.125
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))

        return path
    }
}
