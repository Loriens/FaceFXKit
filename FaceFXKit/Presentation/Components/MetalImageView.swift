//
//  MetalImageView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI
import MetalKit
import CoreImage

struct MetalImageView: UIViewRepresentable {
    let image: CIImage

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.isOpaque = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.backgroundColor = .clear
        context.coordinator.image = image
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        guard context.coordinator.image !== image else { return }
        context.coordinator.image = image
        uiView.setNeedsDisplay()
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        let device: MTLDevice?
        var image: CIImage?
        
        private let commandQueue: MTLCommandQueue?
        private let colorSpace: CGColorSpace
        private let ciContext: CIContext?

        override init() {
            let device = MTLCreateSystemDefaultDevice()
            self.device = device
            self.commandQueue = device?.makeCommandQueue()
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            self.colorSpace = colorSpace
            self.ciContext = device.map {
                CIContext(
                    mtlDevice: $0,
                    options: [
                        .workingColorSpace: colorSpace,
                        .outputColorSpace: colorSpace,
                        .highQualityDownsample: true,
                        .cacheIntermediates: true,
                        .memoryTarget: 512
                    ]
                )
            }
        }

        nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            MainActor.assumeIsolated {
                view.setNeedsDisplay()
            }
        }

        nonisolated func draw(in view: MTKView) {
            MainActor.assumeIsolated {
                render(in: view)
            }
        }

        private func render(in view: MTKView) {
            guard
                let image,
                let ciContext,
                let drawable = view.currentDrawable,
                let commandBuffer = commandQueue?.makeCommandBuffer()
            else { return }

            let extent = image.extent
            let bounds = CGRect(origin: .zero, size: view.drawableSize)
            guard !extent.isEmpty, !bounds.isEmpty else { return }

            // Aspect-fit the image into the drawable.
            let scale = min(bounds.width / extent.width, bounds.height / extent.height)
            let fittedOrigin = CGPoint(
                x: (bounds.width - extent.width * scale) / 2,
                y: (bounds.height - extent.height * scale) / 2
            )

            let fitted = image
                .transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
                .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                .transformed(by: CGAffineTransform(translationX: fittedOrigin.x, y: fittedOrigin.y))
                // Composite over a clear background so the whole texture is written.
                .composited(over: CIImage(color: .clear).cropped(to: bounds))

            ciContext.render(
                fitted,
                to: drawable.texture,
                commandBuffer: commandBuffer,
                bounds: bounds,
                colorSpace: colorSpace
            )

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
