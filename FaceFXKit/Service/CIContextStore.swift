//
//  CIContextStore.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import CoreImage

final class CIContextStore: @unchecked Sendable {
    let primaryContext: CIContext

    init() {
        primaryContext = CIContext(
            options: [
                .highQualityDownsample: true,
                .cacheIntermediates: true,
                .memoryTarget: 512
            ]
        )
    }
}
