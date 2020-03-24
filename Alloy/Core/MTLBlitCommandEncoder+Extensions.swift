//
//  MTLBlitCommandEncoder+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 03.10.2018.
//

import Metal.MTLBlitCommandEncoder

public extension MTLBlitCommandEncoder {
    func copy(region: MTLRegion, from texture: MTLTexture,
              to targetOrigin: MTLOrigin, of targetTexture: MTLTexture,
              sourceSlice: Int = 0, sourceLevel: Int = 0,
              destinationSlice: Int = 0, destionationLevel: Int = 0) {
        self.copy(from: texture,
                  sourceSlice: sourceSlice, sourceLevel: sourceLevel,
                  sourceOrigin: region.origin, sourceSize: region.size,
                  to: targetTexture,
                  destinationSlice: destinationSlice, destinationLevel: destionationLevel,
                  destinationOrigin: targetOrigin)
    }
    
    func copy(texture: MTLTexture,
              to targetOrigin: MTLOrigin, of targetTexture: MTLTexture,
              sourceSlice: Int = 0, sourceLevel: Int = 0,
              destinationSlice: Int = 0, destionationLevel: Int = 0) {
        let region = texture.region
        self.copy(from: texture,
                  sourceSlice: sourceSlice, sourceLevel: sourceLevel,
                  sourceOrigin: region.origin, sourceSize: region.size,
                  to: targetTexture,
                  destinationSlice: destinationSlice, destinationLevel: destionationLevel,
                  destinationOrigin: targetOrigin)
    }
}
