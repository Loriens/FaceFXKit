//
//  CIContextStore.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import Foundation
import CoreImage
import Metal

/// Store for managing shared CIContext instances for optimal performance
final class CIContextStore {
    /// High-performance Metal-based context for image processing
    let metalContext: CIContext
    
    /// CPU-based context for fallback scenarios
    let cpuContext: CIContext
    
    /// Primary context - uses Metal if available, falls back to CPU
    var primaryContext: CIContext {
        return metalContext
    }
    
    init() {
        // Try to create Metal-based context for best performance
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalContext = CIContext(mtlDevice: metalDevice, options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
                .useSoftwareRenderer: false
            ])
        } else {
            // Fallback to CPU context
            self.metalContext = CIContext(options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
                .useSoftwareRenderer: true
            ])
        }
        
        // CPU context for specific use cases
        self.cpuContext = CIContext(options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB(),
            .useSoftwareRenderer: true
        ])
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
