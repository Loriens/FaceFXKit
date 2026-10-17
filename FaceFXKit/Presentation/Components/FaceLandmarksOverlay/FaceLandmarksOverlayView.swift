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

    @State private var showFullView = false

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
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showFullView.toggle()
            } label: {
                Image(systemName: showFullView ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.6), in: .circle)
            }
            .padding(.trailing, 10)
        }
    }

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
            path.addLines(Array(points.dropFirst()))
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
        let center = CGPoint(x: imageFrame.width / 2, y: imageFrame.height / 2)

        return CGPoint(
            x: (point.x - center.x) * imageScale + center.x + imageOffset.width,
            y: (point.y - center.y) * imageScale + center.y + imageOffset.height
        )
    }
}
