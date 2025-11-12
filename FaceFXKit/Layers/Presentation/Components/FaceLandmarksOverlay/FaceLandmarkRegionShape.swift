//
//  FaceLandmarkRegionShape.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 01/10/2025.
//

import Vision
import SwiftUI

struct FaceLandmarkRegionShape: Shape {
    let points: [CGPoint]
    let isClosedPath: Bool

    func path(in rect: CGRect) -> Path {
        let path = CGMutablePath()

        path.move(to: points[0])

        for index in 1..<points.count {
            path.addLine(to: points[index])
        }

        if isClosedPath {
            path.closeSubpath()
        }

        return Path(path)
    }
}
