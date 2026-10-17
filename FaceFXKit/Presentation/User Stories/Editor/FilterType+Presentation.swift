//
//  FilterType+Presentation.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 17/10/2026.
//

import SwiftUI

extension FilterType {
    var hairColorName: String? {
        switch self {
        case .hairColorBlack:          "Black"
        case .hairColorDarkBrown:      "Dark Brown"
        case .hairColorBrown:          "Brown"
        case .hairColorLightBrown:     "Light Brown"
        case .hairColorBlonde:         "Blonde"
        case .hairColorPlatinumBlonde: "Platinum"
        case .hairColorRed:            "Red"
        case .hairColorAuburn:         "Auburn"
        case .hairColorCopper:         "Copper"
        case .hairColorBurgundy:       "Burgundy"
        default:                       nil
        }
    }

    var swatchColor: Color? {
        switch self {
        case .hairColorBlack:          .hairBlack
        case .hairColorDarkBrown:      .hairDarkBrown
        case .hairColorBrown:          .hairBrown
        case .hairColorLightBrown:     .hairLightBrown
        case .hairColorBlonde:         .hairBlonde
        case .hairColorPlatinumBlonde: .hairPlatinumBlonde
        case .hairColorRed:            .hairRed
        case .hairColorAuburn:         .hairAuburn
        case .hairColorCopper:         .hairCopper
        case .hairColorBurgundy:       .hairBurgundy
        default:                       nil
        }
    }

    func formattedIntensity(_ intensity: Float) -> String {
        let percent = Int((intensity * 100).rounded())
        switch preferredSliderMode {
        case .bipolar:
            return percent == 0 ? "0" : Self.signed(percent)
        case .unipolar:
            return "\(percent)%"
        }
    }

    func appliedSummary(intensity: Float) -> String {
        let percent = Int((intensity * 100).rounded())
        if let hairColorName {
            return "\(hairColorName) hair \(percent)%"
        }
        return "\(displayName) \(Self.signed(percent))"
    }

    private static func signed(_ value: Int) -> String {
        (value > 0 ? "+" : "−") + "\(abs(value))"
    }
}
