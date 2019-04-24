//
//  CVPixelFormat+MTLTexture.swift
//  GeometryStabilizer
//
//  Created by Andrey Volodin on 20.10.17.
//  Copyright © 2017 Andrey Volodin. All rights reserved.
//

import Metal
import CoreVideo.CVPixelBuffer

public extension CVPixelBuffer {
    func metalTexture(using cache: CVMetalTextureCache, pixelFormat: MTLPixelFormat, planeIndex: Int = 0) -> MTLTexture? {
        let width = CVPixelBufferGetWidthOfPlane(self, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(self, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, cache, self, nil, pixelFormat, width, height, planeIndex, &texture)
        
        var retVal: MTLTexture? = nil
        if status == kCVReturnSuccess {
            retVal = CVMetalTextureGetTexture(texture!)
        }
        
        return retVal
    }
}

public extension MTLContext {
    func makeTextureCache(textureAge: Float = 1.0) -> CVMetalTextureCache? {
        let options = [kCVMetalTextureCacheMaximumTextureAgeKey as NSString: NSNumber(value: textureAge)] as NSDictionary
        
        var videoTextureCache: CVMetalTextureCache? = nil
        let textureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault, options, device, nil, &videoTextureCache)
        if textureCacheError != kCVReturnSuccess {
            print("ERROR: Wasn't able to create CVMetalTextureCache")
            return nil
        }
        
        return videoTextureCache
    }
}

#if targetEnvironment(simulator)
// This is a mimic for CoreVideo APIs that are not available on simulator
// This is needed to release a library through CocoaPods
public typealias CVMetalTexture = CVImageBuffer
public class CVMetalTextureCache {}
public func CVMetalTextureCacheCreate(_ allocator: CFAllocator?, _ cacheAttributes: CFDictionary?, _ metalDevice: MTLDevice, _ textureAttributes: CFDictionary?, _ cacheOut: UnsafeMutablePointer<CVMetalTextureCache?>) -> CVReturn {
    return kCVReturnError
}
public func CVMetalTextureCacheCreateTextureFromImage(_ allocator: CFAllocator?,
                                                      _ textureCache: CVMetalTextureCache,
                                                      _ sourceImage: CVImageBuffer,
                                                      _ textureAttributes: CFDictionary?,
                                                      _ pixelFormat: MTLPixelFormat,
                                                      _ width: Int,
                                                      _ height: Int,
                                                      _ planeIndex: Int,
                                                      _ textureOut: UnsafeMutablePointer<CVMetalTexture?>) -> CVReturn {
    return kCVReturnError
}
public func CVMetalTextureGetTexture(_ image: CVMetalTexture) -> MTLTexture? {
    return nil
}
#endif
