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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(faceData.faces, id: \.id) { face in
                    FaceBoundingBoxShape(observation: face.observation)
                        .stroke(Color.accent, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                        .scaleEffect(imageScale)
                        .offset(imageOffset)

                    if let landmarks = face.landmarks {
                        landmarkPoints(
                            regions: [
                                landmarks.faceContour,
                                landmarks.leftEyebrow,
                                landmarks.rightEyebrow,
                                landmarks.leftEye,
                                landmarks.rightEye,
                                landmarks.outerLips,
                                landmarks.innerLips
                            ],
                            imageFrame: geometry.size
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func landmarkPoints(
        regions: [FaceObservation.Landmarks2D.Region],
        imageFrame: CGSize
    ) -> some View {
        let points = regions.flatMap { region in
            region
                .pointsInImageCoordinates(imageFrame, origin: .upperLeft)
                .map { convertToScaledAndOffsetCoordinates($0, imageFrame: imageFrame) }
        }

        return Canvas { context, _ in
            for point in points {
                let dotRect = CGRect(x: point.x - 2.8, y: point.y - 2.8, width: 5.6, height: 5.6)
                context.fill(Path(ellipseIn: dotRect), with: .color(.accent))
            }
        }
    }

    private func convertToScaledAndOffsetCoordinates(_ point: CGPoint, imageFrame: CGSize) -> CGPoint {
        let center = CGPoint(x: imageFrame.width / 2, y: imageFrame.height / 2)

        return CGPoint(
            x: (point.x - center.x) * imageScale + center.x + imageOffset.width,
            y: (point.y - center.y) * imageScale + center.y + imageOffset.height
        )
    }
}
