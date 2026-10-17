//
//  HeadSizeFilter.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 19/08/2025.
//

@preconcurrency import CoreImage

final class HeadSizeFilter: CIFilter, @unchecked Sendable {
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputCenter: CIVector?
    @objc dynamic var inputRadiusA: CGFloat = 0
    @objc dynamic var inputRadiusB: CGFloat = 0
    @objc dynamic var inputHeadAngle: CGFloat = 0
    @objc dynamic var inputValue: CGFloat = 1

    private static let kernel: CIWarpKernel = {
        guard
            let url = Bundle.main.url(forResource: "default", withExtension: "metallib"),
            let data = try? Data(contentsOf: url),
            let kernel = try? CIWarpKernel(functionName: "headSize", fromMetalLibraryData: data)
        else {
            fatalError("HeadSizeFilter: Could not load HeadSizeFilter.metal")
        }
        return kernel
    }()

    override var outputImage: CIImage? {
        guard let inputImage, let inputCenter else { return inputImage }

        let output = Self.kernel.apply(
            extent: inputImage.extent,
            roiCallback: { _, rect in rect },
            image: inputImage,
            arguments: [inputCenter, inputRadiusA, inputRadiusB, inputValue, inputHeadAngle]
        )
        return output?.cropped(to: inputImage.extent) ?? inputImage
    }
}
