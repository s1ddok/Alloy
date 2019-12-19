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
        let textureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault, options, device, nil, &videoTextureCache);
        if textureCacheError != kCVReturnSuccess {
            print("ERROR: Wasn't able to create CVMetalTextureCache")
            return nil
        }
        
        return videoTextureCache
    }
}

public extension MTLTexture {

    var pixelBuffer: CVPixelBuffer? {
        guard let cvPixelFormat = self.pixelFormat
                                      .compatibleCVPixelFormat
        else { return nil }

        var pb: CVPixelBuffer? = nil
        var status = try CVPixelBufferCreate(nil,
                                             self.width,
                                             self.height,
                                             cvPixelFormat,
                                             nil,
                                             &pb)
        guard status == kCVReturnSuccess,
              let pixelBuffer = pb
        else { return nil }

        status = CVPixelBufferLockBaseAddress(pixelBuffer, [])
        guard status == kCVReturnSuccess,
              let pixelBufferBaseAdress = CVPixelBufferGetBaseAddress(pixelBuffer)
        else { return nil }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        self.getBytes(pixelBufferBaseAdress,
                      bytesPerRow: bytesPerRow,
                      from: self.region,
                      mipmapLevel: 0)

        status = CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        guard status == kCVReturnSuccess
        else { return nil }

        return pixelBuffer
    }

}
