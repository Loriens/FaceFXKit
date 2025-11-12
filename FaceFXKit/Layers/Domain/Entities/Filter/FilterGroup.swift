//
//  FilterGroup.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 26/07/2025.
//

import Foundation

enum FilterGroup: String, CaseIterable, Codable {
    // Size filter groups
    case head = "Head"

    // Hair filter groups
    case otherColorEffects = "Other Color Effects"
    case hairColors = "Hair Colors"
    case temperature = "Temperature"
    case tint = "Tint"
    case saturation = "Saturation"

    var filterTypes: [FilterType] {
        switch self {
        case .head:
            return [.headSize]
        case .otherColorEffects:
            return [.hue, .colorTone, .highlights]
        case .hairColors:
            return [.hairColorBlack, .hairColorDarkBrown, .hairColorBrown, .hairColorLightBrown, .hairColorBlonde, .hairColorPlatinumBlonde, .hairColorRed, .hairColorAuburn, .hairColorCopper, .hairColorBurgundy]
        case .temperature:
            return [.warmth, .coolness, .balance]
        case .tint:
            return [.magentaGreen, .tintBalance, .colorCast]
        case .saturation:
            return [.vibrance, .intensity, .richness]
        }
    }

    var category: FilterCategory {
        FilterCategory.allCases.first { $0.groups.contains(self) } ?? .sizes
    }
}
