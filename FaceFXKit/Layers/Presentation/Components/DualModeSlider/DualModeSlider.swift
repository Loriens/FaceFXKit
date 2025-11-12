//
//  DualModeSlider.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 28/01/2025.
//

import SwiftUI

enum SliderMode {
    case unipolar
    case bipolar
}

struct DualModeSlider: UIViewRepresentable {
    @Binding var value: Double
    var mode: SliderMode
    var step: Double? = nil
    var trackHeight: CGFloat = 6
    var thumbSize: CGFloat = 24
    var snapToZeroDeadband: Double = 0.05
    var onEditingChanged: (Bool) -> Void = { _ in }
    
    func makeUIView(context: Context) -> UIDualModeSlider {
        let slider = UIDualModeSlider()
        slider.mode = mode
        slider.step = step
        slider.trackHeight = trackHeight
        slider.thumbSize = thumbSize
        slider.snapToZeroDeadband = snapToZeroDeadband

        slider.trackColor = UIColor.systemGray4
        slider.activeTrackColor = UIColor.systemBlue
        slider.thumbColor = UIColor.white
        slider.thumbBorderColor = UIColor.systemGray3

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingDidBegin(_:)),
            for: .editingDidBegin
        )
        
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingDidEnd(_:)),
            for: .editingDidEnd
        )
        
        return slider
    }
    
    func updateUIView(_ uiView: UIDualModeSlider, context: Context) {
        uiView.mode = mode
        uiView.step = step
        uiView.trackHeight = trackHeight
        uiView.thumbSize = thumbSize
        uiView.snapToZeroDeadband = snapToZeroDeadband

        if abs(uiView.value - value) > 0.01 {
            uiView.setValue(value, animated: false)
        }

        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    class Coordinator: NSObject {
        var parent: DualModeSlider
        
        init(_ parent: DualModeSlider) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ slider: UIDualModeSlider) {
            if abs(parent.value - slider.value) > 0.001 {
                parent.value = slider.value
            }
        }
        
        @objc func editingDidBegin(_ slider: UIDualModeSlider) {
            parent.onEditingChanged(true)
        }
        
        @objc func editingDidEnd(_ slider: UIDualModeSlider) {
            parent.onEditingChanged(false)
        }
    }
}
