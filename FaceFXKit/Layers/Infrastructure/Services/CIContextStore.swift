//
//  CIContextStore.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import CoreImage
import Metal

/// Store for the shared CIContext instance for optimal performance.
///
/// @unchecked Sendable safety invariant: the only stored property is an
/// immutable `CIContext`, which Apple documents as thread-safe, so this store
/// can be used from any isolation.
final class CIContextStore: @unchecked Sendable {
    /// Primary context — Metal-backed when available, software otherwise.
    let primaryContext: CIContext

    init() {
        // Try to create Metal-based context for best performance
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.primaryContext = CIContext(mtlDevice: metalDevice, options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
                .useSoftwareRenderer: false
            ])
        } else {
            // Fallback to CPU context
            self.primaryContext = CIContext(options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
                .useSoftwareRenderer: true
            ])
        }
    }
    
    /// Creates CGImage from CIImage using the optimal context
    func createCGImage(from ciImage: CIImage) -> CGImage? {
        return primaryContext.createCGImage(ciImage, from: ciImage.extent)
    }
    
    /// Creates CGImage from CIImage with specific rect using the optimal context
    func createCGImage(from ciImage: CIImage, in rect: CGRect) -> CGImage? {
        return primaryContext.createCGImage(ciImage, from: rect)
    }
}
