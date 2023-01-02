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
        
        if #available(iOS 15.0, macOS 12.5, *) {
            copy.compressionType = self.compressionType
        }

        return copy
    }

}
