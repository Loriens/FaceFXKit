//
//  UIDualModeSlider.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 28/01/2025.
//

import UIKit

final class UIDualModeSlider: UIControl {
    
    // MARK: - Properties

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: max(thumbSize, trackHeight))
    }

    var mode: SliderMode = .unipolar {
        didSet {
            if oldValue != mode {
                updateAppearance()
                setNeedsLayout()
            }
        }
    }
    
    var value: Double = 0.0 {
        didSet {
            let clampedValue = clampedValue(value)
            if abs(oldValue - clampedValue) > 0.01 {
                value = clampedValue
                updateThumbPosition()
                updateActiveTrack()
            }
        }
    }
    
    var trackColor: UIColor = UIColor.systemGray4 {
        didSet { trackLayer.fillColor = trackColor.cgColor }
    }
    
    var activeTrackColor: UIColor = UIColor.systemBlue {
        didSet { activeTrackLayer.fillColor = activeTrackColor.cgColor }
    }
    
    var thumbColor: UIColor = UIColor.white {
        didSet { thumbLayer.fillColor = thumbColor.cgColor }
    }
    
    var thumbBorderColor: UIColor = UIColor.systemGray3 {
        didSet { thumbLayer.borderColor = thumbBorderColor.cgColor }
    }

    var step: Double? = nil
    var trackHeight: CGFloat = 6
    var thumbSize: CGFloat = 24
    var snapToZeroDeadband: Double = 0.05

    private var trackLayer = CAShapeLayer()
    private var activeTrackLayer = CAShapeLayer()
    private var thumbLayer = CAShapeLayer()
    
    private var trackWidth: CGFloat = 0
    private var isDragging = false
    private var dragStartValue: Double = 0
    private var dragStartPoint: CGPoint = .zero
    
    // MARK: - Computed Properties
    
    private var normalizedValue: Double {
        switch mode {
        case .unipolar:
            return max(0, min(1, value))
        case .bipolar:
            return max(-1, min(1, value))
        }
    }
    
    private var thumbPosition: CGFloat {
        guard trackWidth > 0 else { return thumbSize / 2 }
        
        let normalizedVal = normalizedValue
        let position: CGFloat
        
        switch mode {
        case .unipolar:
            position = CGFloat(normalizedVal) * trackWidth
        case .bipolar:
            position = CGFloat((normalizedVal + 1) / 2) * trackWidth
        }
        
        return position + thumbSize / 2
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSlider()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSlider()
    }
    
    // MARK: - Setup Functions
    
    private func setupSlider() {
        // Setup track layer
        trackLayer.fillColor = trackColor.cgColor
        layer.addSublayer(trackLayer)
        
        // Setup active track layer
        activeTrackLayer.fillColor = activeTrackColor.cgColor
        layer.addSublayer(activeTrackLayer)
        
        // Setup thumb layer
        thumbLayer.fillColor = thumbColor.cgColor
        thumbLayer.borderColor = thumbBorderColor.cgColor
        thumbLayer.borderWidth = 2
        thumbLayer.shadowColor = UIColor.black.cgColor
        thumbLayer.shadowOpacity = 0.2
        thumbLayer.shadowOffset = CGSize(width: 0, height: 1)
        thumbLayer.shadowRadius = 2
        layer.addSublayer(thumbLayer)
        
        updateAppearance()
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        trackWidth = bounds.width - thumbSize

        updateTrackLayers()
        updateThumbPosition()
        updateActiveTrack()
    }
    
    private func updateTrackLayers() {
        let trackRect = CGRect(
            x: thumbSize / 2,
            y: (bounds.height - trackHeight) / 2,
            width: trackWidth,
            height: trackHeight
        )
        
        trackLayer.path = UIBezierPath(
            roundedRect: trackRect,
            cornerRadius: trackHeight / 2
        ).cgPath
    }
    
    private func updateThumbPosition() {
        let thumbRect = CGRect(
            x: thumbPosition - thumbSize / 2,
            y: (bounds.height - thumbSize) / 2,
            width: thumbSize,
            height: thumbSize
        )
        
        let thumbPath = UIBezierPath(ovalIn: thumbRect).cgPath
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        thumbLayer.path = thumbPath
        CATransaction.commit()
    }
    
    private func updateActiveTrack() {
        let trackRect = CGRect(
            x: thumbSize / 2,
            y: (bounds.height - trackHeight) / 2,
            width: trackWidth,
            height: trackHeight
        )
        
        let activeRect: CGRect
        let currentPosition = thumbPosition
        
        switch mode {
        case .unipolar:
            // Fill from left to current position
            activeRect = CGRect(
                x: trackRect.minX,
                y: trackRect.minY,
                width: max(0, currentPosition),
                height: trackHeight
            )
            
        case .bipolar:
            // Fill from center to current position
            let centerX = trackRect.minX + trackWidth / 2
            let fillWidth = abs(currentPosition - centerX)
            let fillOffset = min(centerX, currentPosition)
            
            activeRect = CGRect(
                x: fillOffset,
                y: trackRect.minY,
                width: fillWidth,
                height: trackHeight
            )
        }
        
        let activePath = UIBezierPath(
            roundedRect: activeRect,
            cornerRadius: trackHeight / 2
        ).cgPath
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        activeTrackLayer.path = activePath
        CATransaction.commit()
    }
    
    private func updateAppearance() {
        trackLayer.fillColor = trackColor.cgColor
        activeTrackLayer.fillColor = activeTrackColor.cgColor
        thumbLayer.fillColor = thumbColor.cgColor
        thumbLayer.borderColor = thumbBorderColor.cgColor
    }
    
    // MARK: - Value Management
    
    private func clampedValue(_ val: Double) -> Double {
        switch mode {
        case .unipolar:
            return max(0, min(1, val))
        case .bipolar:
            return max(-1, min(1, val))
        }
    }
    
    private func quantizeValue(_ val: Double) -> Double {
        guard let stepSize = step, stepSize > 0 else {
            return val
        }
        return round(val / stepSize) * stepSize
    }
    
    private func applySnapToZero() {
        if mode == .bipolar && abs(value) <= snapToZeroDeadband {
            setValue(0, animated: false)
        }
    }
    
    func setValue(_ newValue: Double, animated: Bool) {
        let clampedVal = clampedValue(newValue)
        let quantizedVal = quantizeValue(clampedVal)
        
        if abs(value - quantizedVal) > 0.001 {
            value = quantizedVal
            updateThumbPosition()
            updateActiveTrack()
            sendActions(for: .valueChanged)
        }
    }
    
    // MARK: - Touch Handling
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        
        // Check if touch is within slider bounds
        let sliderBounds = CGRect(
            x: 0,
            y: (bounds.height - max(thumbSize, trackHeight)) / 2,
            width: bounds.width,
            height: max(thumbSize, trackHeight)
        )
        
        guard sliderBounds.contains(touchPoint) else { return false }
        
        isDragging = true
        dragStartValue = value
        dragStartPoint = touchPoint

        sendActions(for: .editingDidBegin)
        
        // If tap is not on thumb, jump to that position
        let thumbCenter = CGPoint(x: thumbPosition, y: bounds.height / 2)
        let distanceFromThumb = sqrt(pow(touchPoint.x - thumbCenter.x, 2) + pow(touchPoint.y - thumbCenter.y, 2))
        
        if distanceFromThumb > thumbSize / 2 {
            updateValueFromPoint(touchPoint)
        }
        
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isDragging else { return false }
        
        let touchPoint = touch.location(in: self)
        updateValueFromPoint(touchPoint)
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard isDragging else { return }
        
        isDragging = false
        
        // Apply snap-to-zero for bipolar mode
        if mode == .bipolar {
            applySnapToZero()
        }
        
        sendActions(for: .editingDidEnd)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        guard isDragging else { return }
        
        isDragging = false
        sendActions(for: .editingDidEnd)
    }
    
    private func updateValueFromPoint(_ point: CGPoint) {
        let trackPosition = max(0, min(trackWidth, point.x - thumbSize / 2))
        let normalizedPosition = Double(trackPosition / trackWidth)
        
        let newValue: Double
        switch mode {
        case .unipolar:
            newValue = normalizedPosition
        case .bipolar:
            newValue = (normalizedPosition * 2) - 1
        }
        
        setValue(newValue, animated: false)
    }
}
