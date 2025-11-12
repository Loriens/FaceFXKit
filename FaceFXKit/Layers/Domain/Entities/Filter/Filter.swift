//
//  Filter.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation

struct Filter {
    let id: UUID
    let type: FilterType
    let name: String
    let group: FilterGroup
    let category: FilterCategory
    var intensity: Float
    let minValue: Float
    let maxValue: Float
    let defaultValue: Float

    var isActive: Bool {
        return intensity != defaultValue
    }

    mutating func updateIntensity(_ value: Float) {
        self.intensity = max(minValue, min(maxValue, value))
    }

    mutating func reset() {
        self.intensity = defaultValue
    }

    init(type: FilterType, intensity: Float = 0.0) {
        self.id = UUID()
        self.type = type
        self.name = type.displayName
        self.group = type.group
        self.category = type.category
        self.intensity = intensity
        self.minValue = -1.0
        self.maxValue = 1.0
        self.defaultValue = 0.0
    }
}
