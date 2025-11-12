//
//  CGPoint+Extensions.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 26/07/2025.
//

import Foundation
import CoreGraphics
import CoreImage

extension CGPoint {
    /// Calculate the distance between two points
    func distance(_ other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Convert CGPoint to CIVector
    var asCIVector: CIVector {
        return CIVector(x: x, y: y)
    }
}

extension Array where Element == CGPoint {
    var center: CGPoint {
        guard !isEmpty else { return CGPoint.zero }
        
        let sumX = reduce(0) { $0 + $1.x }
        let sumY = reduce(0) { $0 + $1.y }
        
        return CGPoint(
            x: sumX / CGFloat(count),
            y: sumY / CGFloat(count)
        )
    }
    
    /// Calculate the bounding rectangle of an array of CGPoints
    var boundingRect: CGRect {
        guard !isEmpty else { return CGRect.zero }
        
        let minX = map(\.x).min() ?? 0
        let maxX = map(\.x).max() ?? 0
        let minY = map(\.y).min() ?? 0
        let maxY = map(\.y).max() ?? 0
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}

extension CGPoint {
    /// Subtract two points
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    /// Add two points
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    /// Multiply point by scalar
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension Array {
    /// Safe subscript access
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
