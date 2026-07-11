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
        guard let category = Self.categoryByGroup[self] else {
            preconditionFailure("FilterGroup \(self) is not listed in any FilterCategory.groups")
        }
        return category
    }

    /// `FilterCategory.groups` is the single source of truth; this map is its
    /// cached inversion.
    private static let categoryByGroup: [FilterGroup: FilterCategory] = {
        var map: [FilterGroup: FilterCategory] = [:]
        for category in FilterCategory.allCases {
            for group in category.groups {
                map[group] = category
            }
        }
        return map
    }()
}
