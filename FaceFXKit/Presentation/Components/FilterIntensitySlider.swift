//
//  FilterIntensitySlider.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI

enum SliderMode {
    case unipolar
    case bipolar
}

extension FilterType {
    var preferredSliderMode: SliderMode {
        switch self {
        case .headSize, .balance, .magentaGreen, .tintBalance, .hue:
            .bipolar
        default:
            .unipolar
        }
    }
}

struct FilterIntensitySlider: View {
    @Binding var value: Double
    let mode: SliderMode
    var step: Double = 0.01
    var snapToZeroDeadband: Double = 0.05

    @Environment(\.isEnabled) private var isEnabled

    private static let thumbDiameter: CGFloat = 24
    private static let trackHeight: CGFloat = 4
    private static let touchOverhang: CGFloat = 12
    private static let accessibilityStep: Double = 0.1

    private var range: ClosedRange<Double> {
        mode == .bipolar ? -1...1 : 0...1
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let origin: Double = mode == .bipolar ? 0.5 : 0

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.track)
                    .frame(height: Self.trackHeight)

                if mode == .bipolar {
                    Capsule()
                        .fill(Color.trackTick)
                        .frame(width: 2, height: 14)
                        .offset(x: width / 2 - 1)
                }

                Capsule()
                    .fill(Color.accent)
                    .frame(width: abs(fraction - origin) * width, height: Self.trackHeight)
                    .offset(x: min(fraction, origin) * width)

                Circle()
                    .fill(Color.textPrimary)
                    .frame(width: Self.thumbDiameter, height: Self.thumbDiameter)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    .offset(x: fraction * width - Self.thumbDiameter / 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle().inset(by: -Self.touchOverhang))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isEnabled, width > 0 else { return }
                        let fraction = min(max(gesture.location.x / width, 0), 1)
                        setValue(range.lowerBound + fraction * (range.upperBound - range.lowerBound))
                    }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Filter intensity")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: setValue(min(value + Self.accessibilityStep, range.upperBound))
            case .decrement: setValue(max(value - Self.accessibilityStep, range.lowerBound))
            @unknown default: break
            }
        }
    }

    private func setValue(_ newValue: Double) {
        var quantized = (newValue / step).rounded() * step
        if mode == .bipolar, abs(quantized) <= snapToZeroDeadband {
            quantized = 0
        }
        guard quantized != value else { return }
        value = quantized
    }
}
