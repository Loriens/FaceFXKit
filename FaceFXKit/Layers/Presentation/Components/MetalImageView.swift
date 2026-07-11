//
//  MetalImageView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2026.
//

import SwiftUI
import MetalKit
import CoreImage

/// Metal-backed preview that renders a `CIImage` filter graph directly into an
/// `MTKView` drawable — no intermediate `CGImage` round trip.
struct MetalImageView: UIViewRepresentable {
    let image: CIImage

    func makeCoordinator() -> Renderer {
        Renderer(ciContext: DIContainer.shared.ciContextStore.primaryContext)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.delegate = context.coordinator
        view.framebufferOnly = false        // Core Image writes into the drawable texture
        view.isPaused = true                // redraw on demand only, not per frame
        view.enableSetNeedsDisplay = true
        view.isOpaque = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.backgroundColor = .clear
        context.coordinator.image = image
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Zoom/pan re-evaluations reuse the same CIImage instance — only a new
        // filter result should trigger a redraw.
        guard context.coordinator.image !== image else { return }
        context.coordinator.image = image
        uiView.setNeedsDisplay()
    }

    @MainActor
    final class Renderer: NSObject, MTKViewDelegate {
        var image: CIImage?
        let device: MTLDevice?

        private let ciContext: CIContext
        private let commandQueue: MTLCommandQueue?
        private let colorSpace = CGColorSpaceCreateDeviceRGB()

        init(ciContext: CIContext) {
            self.ciContext = ciContext
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()
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
                let drawable = view.currentDrawable,
                let commandBuffer = commandQueue?.makeCommandBuffer()
            else { return }

            let drawableSize = view.drawableSize
            let bounds = CGRect(origin: .zero, size: drawableSize)

            guard
                image.extent.width > 0, image.extent.height > 0,
                bounds.width > 0, bounds.height > 0
            else { return }

            // Aspect-fit the image into the drawable.
            let scale = min(
                drawableSize.width / image.extent.width,
                drawableSize.height / image.extent.height
            )
            let scaledSize = CGSize(
                width: image.extent.width * scale,
                height: image.extent.height * scale
            )
            let fittedOrigin = CGPoint(
                x: (drawableSize.width - scaledSize.width) / 2,
                y: (drawableSize.height - scaledSize.height) / 2
            )

            let fitted = image
                .transformed(by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY))
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
