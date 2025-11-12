//
//  FilterType.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 26/07/2025.
//

import Foundation

enum FilterType: String, CaseIterable, Codable {
    // Head filters
    case headSize = "head_size"

    // Hair Color filters
    case hairColorBlack = "hair_color_black"
    case hairColorDarkBrown = "hair_color_dark_brown"
    case hairColorBrown = "hair_color_brown"
    case hairColorLightBrown = "hair_color_light_brown"
    case hairColorBlonde = "hair_color_blonde"
    case hairColorPlatinumBlonde = "hair_color_platinum_blonde"
    case hairColorRed = "hair_color_red"
    case hairColorAuburn = "hair_color_auburn"
    case hairColorCopper = "hair_color_copper"
    case hairColorBurgundy = "hair_color_burgundy"

    // Temperature filters
    case warmth = "warmth"
    case coolness = "coolness"
    case balance = "balance"

    // Tint filters
    case magentaGreen = "magenta_green"
    case tintBalance = "tint_balance"
    case colorCast = "color_cast"

    // Saturation filters
    case vibrance = "vibrance"
    case intensity = "intensity"
    case richness = "richness"

    // Color filters
    case hue = "hue"
    case colorTone = "color_tone"
    case highlights = "highlights"

    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var group: FilterGroup {
        FilterGroup.allCases.first { $0.filterTypes.contains(self) } ?? .head
    }

    var category: FilterCategory {
        group.category
    }
}
