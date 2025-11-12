//
//  FilterCategory.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 25/07/2025.
//

import Foundation

enum FilterCategory: String, CaseIterable {
    case sizes = "Sizes"
    case hair = "Hair"
    
    var groups: [FilterGroup] {
        switch self {
        case .sizes:
            return [.head]
        case .hair:
            return [.hairColors, .temperature, .tint, .saturation, .otherColorEffects]
        }
    }
}
