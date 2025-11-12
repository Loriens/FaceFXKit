//
//  FilterConfiguration.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 25/07/2025.
//

import Foundation

struct FilterConfiguration {
    let filter: FilterType
    private(set) var intensity: Float

    mutating func updateFilter(intensity: Float) {
        self.intensity = intensity
    }
} 
