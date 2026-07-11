//
//  FaceLandmarksOverlayView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 25/07/2025.
//

import SwiftUI
import Vision

struct FaceLandmarksOverlayView: View {
    let faceData: FaceTrackingResult
    let imageScale: CGFloat
    let imageOffset: CGSize

    @State private var showFullView: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(faceData.faces, id: \.id) { face in
                    if showFullView {
                        FaceBoundingBoxShape(observation: face.observation)
                            .stroke(.green, lineWidth: 2)
                    }

                    if let landmarks = face.landmarks {
                        landmarkRegionOverlay(region: landmarks.faceContour, color: .red, imageFrame: geometry.size)
                        landmarkRegionOverlay(region: landmarks.leftEyebrow, color: .orange, imageFrame: geometry.size)
                        landmarkRegionOverlay(region: landmarks.rightEyebrow, color: .orange, imageFrame: geometry.size)
                        landmarkRegionOverlay(region: landmarks.leftEye, color: .green, imageFrame: geometry.size)
                        landmarkRegionOverlay(region: landmarks.rightEye, color: .green, imageFrame: geometry.size)
                        landmarkRegionOverlay(region: landmarks.outerLips, color: .purple, imageFrame: geometry.size)
                        landmarkRegionOverlay(region: landmarks.innerLips, color: .blue, imageFrame: geometry.size)
                    }
                }

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showFullView.toggle()
                        } label: {
                            Image(systemName: showFullView ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                )
                        }
                        .padding(.trailing, 10)
                    }
                    Spacer()
                }
            }
        }
    }

    /// Draws a landmark region — its connecting path plus a dot per point —
    /// in a single `Canvas` instead of one view per point.
    private func landmarkRegionOverlay(
        region: FaceObservation.Landmarks2D.Region,
        color: Color,
        imageFrame: CGSize
    ) -> some View {
        let points = region
            .pointsInImageCoordinates(imageFrame, origin: .upperLeft)
            .map { convertToScaledAndOffsetCoordinates($0, imageFrame: imageFrame) }
        let isClosedPath = region.pointsClassification == .closedPath

        return Canvas { context, _ in
            guard let firstPoint = points.first else { return }

            var path = Path()
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            if isClosedPath {
                path.closeSubpath()
            }
            context.stroke(path, with: .color(color), lineWidth: 2)

            for point in points {
                let dotRect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
                context.fill(Path(ellipseIn: dotRect), with: .color(color))
            }
        }
        .allowsHitTesting(false)
    }

    private func convertToScaledAndOffsetCoordinates(_ point: CGPoint, imageFrame: CGSize) -> CGPoint {
        // Get the center of the image frame for proper zoom scaling
        let frameCenter = CGPoint(
            x: imageFrame.width / 2,
            y: imageFrame.height / 2
        )

        // Step 1: Translate point relative to center
        let centeredPoint = CGPoint(
            x: point.x - frameCenter.x,
            y: point.y - frameCenter.y
        )

        // Step 2: Apply zoom scale transformation around center
        let scaledPoint = CGPoint(
            x: centeredPoint.x * imageScale,
            y: centeredPoint.y * imageScale
        )

        // Step 3: Translate back from center
        let scaledBackPoint = CGPoint(
            x: scaledPoint.x + frameCenter.x,
            y: scaledPoint.y + frameCenter.y
        )

        // Step 4: Apply drag offset (same as applied to the image)
        let finalPoint = CGPoint(
            x: scaledBackPoint.x + imageOffset.width,
            y: scaledBackPoint.y + imageOffset.height
        )

        return finalPoint
    }
}
