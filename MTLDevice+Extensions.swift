//
//  MTLDevice+Extensions.swift
//  Alloy-iOS
//
//  Created by Vladimir Pavlov on 06/05/2019.
//

import Metal
import CoreGraphics

@available(iOS 11.0, macOS 10.12, *)
extension MTLDevice {

    public func maxTextureSize(desiredSize: CGSize) -> CGSize {
        let maxSide: CGFloat
        if self.supportsOnly8K() {
            maxSide = 8192 * metalSafeMultiplier
        } else {
            maxSide = 16_384 * metalSafeMultiplier
        }

        guard desiredSize.width > 0, desiredSize.height > 0 else { return .zero }
        let aspectRatio = desiredSize.width / desiredSize.height
        if aspectRatio > 1 {
            let resultWidth = min(desiredSize.width, maxSide)
            let resultHeight = resultWidth / aspectRatio
            return CGSize(width: resultWidth, height: resultHeight)
        } else {
            let resultHeight = min(desiredSize.height, maxSide)
            let resultWidth = resultHeight * aspectRatio
            return CGSize(width: resultWidth, height: resultHeight)
        }
    }

    private func supportsOnly8K() -> Bool {
        #if os(macOS)
        return false
        #else
        if self.supportsFeatureSet(.iOS_GPUFamily1_v4) { return true }
        if self.supportsFeatureSet(.iOS_GPUFamily2_v4) { return true }
        if #available(iOS 12.0, *) {
            if self.supportsFeatureSet(.iOS_GPUFamily1_v5) { return true }
            if self.supportsFeatureSet(.iOS_GPUFamily2_v5) { return true }
        }
        return false
        #endif
    }
}

/// MTLTexture cannot be created if the size is very close to the documented limit.
/// We make images smaller to make sure they can be processed.
/// It also avoids memory issues.
private let metalSafeMultiplier: CGFloat = 0.75
