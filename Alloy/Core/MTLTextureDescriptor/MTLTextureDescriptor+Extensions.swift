//
//  MTLTextureDescriptor+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14.11.2019.
//

import Metal

public extension MTLTextureDescriptor {

    func makeCopy() -> MTLTextureDescriptor {
        let copy = MTLTextureDescriptor()
        copy.pixelFormat = self.pixelFormat
        copy.width = self.width
        copy.height = self.height
        copy.depth = self.depth
        copy.mipmapLevelCount = self.mipmapLevelCount
        copy.sampleCount = self.sampleCount
        copy.arrayLength = self.arrayLength
        copy.resourceOptions = self.resourceOptions
        copy.cpuCacheMode = self.cpuCacheMode
        copy.storageMode = self.storageMode
        copy.usage = self.usage

        if #available(iOS 13.0, macOS 10.15, *) {
            copy.hazardTrackingMode = self.hazardTrackingMode
            copy.allowGPUOptimizedContents = self.allowGPUOptimizedContents
            copy.swizzle = self.swizzle
        }

        return copy
    }

}
