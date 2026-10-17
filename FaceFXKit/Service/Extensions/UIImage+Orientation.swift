//
//  UIImage+Orientation.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 10/08/2025.
//

import UIKit

extension UIImage {
    func imageOrientationToTiffOrientation() -> Int32 {
        switch imageOrientation {
        case .up: 1
        case .upMirrored: 2
        case .down: 3
        case .downMirrored: 4
        case .leftMirrored: 5
        case .right: 6
        case .rightMirrored: 7
        case .left: 8
        @unknown default: 1
        }
    }
}
