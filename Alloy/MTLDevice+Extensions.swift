//
//  MTLDevice+Extensions.swift
//  Alloy-iOS
//
//  Created by Vladimir Pavlov on 06/05/2019.
//

import Metal

@available(iOS 11.0, macOS 10.12, *)
public extension MTLDevice {

    func maxTextureSize(desiredSize: MTLSize) -> MTLSize {
        let maxSide: Int
        if self.supportsOnly8K() {
            maxSide = 8192
        } else {
            maxSide = 16_384
        }

        guard desiredSize.width > 0, desiredSize.height > 0 else { return .zero }
        let aspectRatio = desiredSize.width / desiredSize.height
        if aspectRatio > 1 {
            let resultWidth = min(desiredSize.width, maxSide)
            let resultHeight = resultWidth / aspectRatio
            return MTLSize(width: resultWidth, height: resultHeight, depth: 0)
        } else {
            let resultHeight = min(desiredSize.height, maxSide)
            let resultWidth = resultHeight * aspectRatio
            return MTLSize(width: resultWidth, height: resultHeight, depth: 0)
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
