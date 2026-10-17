//
//  CGPoint+Extensions.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 26/07/2025.
//

import CoreImage

extension CGPoint {
    /// Calculate the distance between two points
    func distance(_ other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }

    /// Convert CGPoint to CIVector
    var asCIVector: CIVector {
        CIVector(x: x, y: y)
    }
}

extension Array where Element == CGPoint {
    var center: CGPoint {
        guard !isEmpty else { return .zero }

        let sum = reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(count), y: sum.y / CGFloat(count))
    }
}
