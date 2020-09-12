import Metal.MTLBlitCommandEncoder

public extension MTLBlitCommandEncoder {
    func copy(region: MTLRegion,
              from source: MTLTexture,
              to targetOrigin: MTLOrigin,
              of target: MTLTexture,
              sourceSlice: Int = 0,
              sourceLevel: Int = 0,
              destinationSlice: Int = 0,
              destionationLevel: Int = 0) {
        self.copy(from: source,
                  sourceSlice: sourceSlice,
                  sourceLevel: sourceLevel,
                  sourceOrigin: region.origin,
                  sourceSize: region.size,
                  to: target,
                  destinationSlice: destinationSlice,
                  destinationLevel: destionationLevel,
                  destinationOrigin: targetOrigin)
    }
    
    func copy(texture: MTLTexture,
              to targetOrigin: MTLOrigin,
              of target: MTLTexture,
              sourceSlice: Int = 0,
              sourceLevel: Int = 0,
              destinationSlice: Int = 0,
              destionationLevel: Int = 0) {
        let region = texture.region
        self.copy(from: texture,
                  sourceSlice: sourceSlice,
                  sourceLevel: sourceLevel,
                  sourceOrigin: region.origin,
                  sourceSize: region.size,
                  to: target,
                  destinationSlice: destinationSlice,
                  destinationLevel: destionationLevel,
                  destinationOrigin: targetOrigin)
    }
}
