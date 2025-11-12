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
    let imageSize: CGSize
    let imageScale: CGFloat
    let imageOffset: CGSize

    @State private var showFullView: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<faceData.faces.count, id: \.self) { faceIndex in
                    let face = faceData.faces[faceIndex]

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
                                .foregroundColor(.white)
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

    private func convert(
        point: CGPoint,
        in boundingBox: CGRect,
        imageSize: CGSize,
        imageFrame: CGSize
    ) -> CGPoint {
        // Step 1: Convert face landmark point to face bounding box coordinates
        let x = boundingBox.origin.x + point.x * boundingBox.size.width
        let y = boundingBox.origin.y + point.y * boundingBox.size.height

        // Step 2: Flip Y coordinate to match UIKit / SwiftUI coordinate system
        let flippedY = 1 - y

        // Step 3: Convert normalized coordinates to image coordinates
        let convertedX = x * imageSize.width
        let convertedY = flippedY * imageSize.height

        let point = CGPoint(x: convertedX, y: convertedY)

        return convertToScaledAndOffsetCoordinates(point, imageFrame: imageFrame)
    }

    private func convert(
        point: NormalizedPoint,
        face: FaceData,
        imageSize: CGSize,
        imageFrame: CGSize
    ) -> CGPoint {
        let point = point.toImageCoordinates(
            from: face.boundingBox,
            imageSize: imageSize,
            origin: .upperLeft
        )

        return convertToScaledAndOffsetCoordinates(point, imageFrame: imageFrame)
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
    
    @ViewBuilder
    private func landmarkRegionOverlay(
        region: FaceObservation.Landmarks2D.Region,
        color: Color,
        imageFrame: CGSize
    ) -> some View {
        let points = region
            .pointsInImageCoordinates(imageFrame, origin: .upperLeft)
            .map { convertToScaledAndOffsetCoordinates($0, imageFrame: imageFrame) }

        ZStack {
            FaceLandmarkRegionShape(points: points, isClosedPath: region.pointsClassification == .closedPath)
                .stroke(color, lineWidth: 2)

            ForEach(Array(0..<points.count), id: \.self) { pointIndex in
                let point = points[pointIndex]

                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .position(point)

                //            if showFullView {
                //                Text("\(pointIndex + 1)")
                //                    .font(.system(size: 8, weight: .bold))
                //                    .foregroundColor(.white)
                //                    .shadow(color: .black, radius: 1, x: 0, y: 0)
                //                    .position(
                //                        x: convertedPoint.x,
                //                        y: convertedPoint.y - 12
                //                    )
                //            }
            }
        }
    }
}

