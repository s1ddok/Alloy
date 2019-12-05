//
//  CVPixelFormat+MTLTexture.swift
//  Alloy
//
//  Created by Andrey Volodin on 20.10.17.
//  Copyright © 2017 Andrey Volodin. All rights reserved.
//

import Metal
import CoreVideo.CVPixelBuffer

public extension CVPixelBuffer {
    func texture(using cache: CVMetalTextureCache,
                 pixelFormat: MTLPixelFormat,
                 planeIndex: Int = 0) -> MTLTexture? {
        let width = CVPixelBufferGetWidthOfPlane(self, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(self, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                               cache,
                                                               self,
                                                               nil,
                                                               pixelFormat,
                                                               width,
                                                               height,
                                                               planeIndex,
                                                               &texture)
        
        var retVal: MTLTexture? = nil
        if status == kCVReturnSuccess {
            retVal = CVMetalTextureGetTexture(texture!)
        }
        
        return retVal
    }
}

public extension MTLContext {
    func textureCache(textureAge: Float = 1.0) throws -> CVMetalTextureCache {
        let optionsKey = kCVMetalTextureCacheMaximumTextureAgeKey as NSString
        let optionsValue = NSNumber(value: textureAge)
        let options = [optionsKey: optionsValue] as NSDictionary
        
        var videoTextureCache: CVMetalTextureCache! = nil
        let textureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                                          options,
                                                          self.device,
                                                          nil,
                                                          &videoTextureCache);
        if textureCacheError != kCVReturnSuccess {
            throw MetalError.MTLContextError.textureCacheCreationFailed
        }
        
        return videoTextureCache
    }
}
