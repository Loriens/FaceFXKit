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
        self == .headSize ? .bipolar : .unipolar
    }
}

struct FilterIntensitySlider: View {
    @Binding var value: Double
    let mode: SliderMode
    var step: Double = 0.01
    var snapToZeroDeadband: Double = 0.05

    private var range: ClosedRange<Double> {
        mode == .bipolar ? -1...1 : 0...1
    }

    private var quantizedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { newValue in
                var quantized = (newValue / step).rounded() * step
                if mode == .bipolar, abs(quantized) <= snapToZeroDeadband {
                    quantized = 0
                }
                value = quantized
            }
        )
    }

    var body: some View {
        Slider(
            value: quantizedValue,
            in: range,
            neutralValue: mode == .bipolar ? 0 : nil
        ) {
            Text("Filter intensity")
        }
    }
}
