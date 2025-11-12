//
//  FaceLandmarks.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 25/07/2025.
//

import Foundation
import Vision

struct FaceLandmarks {
    let all: FaceObservation.Landmarks2D.Region
    let nose: FaceObservation.Landmarks2D.Region
    let leftEye: FaceObservation.Landmarks2D.Region
    let rightEye: FaceObservation.Landmarks2D.Region
    let outerLips: FaceObservation.Landmarks2D.Region
    let innerLips: FaceObservation.Landmarks2D.Region
    let leftEyebrow: FaceObservation.Landmarks2D.Region
    let rightEyebrow: FaceObservation.Landmarks2D.Region
    let faceContour: FaceObservation.Landmarks2D.Region

    init(from landmarks: FaceObservation.Landmarks2D) {
        self.all = landmarks.allPoints
        self.nose = landmarks.nose
        self.leftEye = landmarks.leftEye
        self.rightEye = landmarks.rightEye
        self.outerLips = landmarks.outerLips
        self.innerLips = landmarks.innerLips
        self.leftEyebrow = landmarks.leftEyebrow
        self.rightEyebrow = landmarks.rightEyebrow
        self.faceContour = landmarks.faceContour
    }
}
