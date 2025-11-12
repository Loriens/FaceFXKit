//
//  FaceBoundingBoxShape.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 01/10/2025.
//

import Vision
import SwiftUI

struct FaceBoundingBoxShape: Shape {
    private let normalizedRect: NormalizedRect

    init(observation: any BoundingBoxProviding) {
        normalizedRect = observation.boundingBox
    }

    func path(in rect: CGRect) -> Path {
        let rect = normalizedRect.toImageCoordinates(rect.size, origin: .upperLeft)
        return Path(rect)
    }
}
