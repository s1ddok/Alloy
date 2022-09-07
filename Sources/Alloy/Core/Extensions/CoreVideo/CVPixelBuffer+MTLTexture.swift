import Metal
import CoreVideo.CVPixelBuffer

public extension CVPixelBuffer {

    func metalTexture(using cache: CVMetalTextureCache,
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
        let textureAgeKey = kCVMetalTextureCacheMaximumTextureAgeKey as NSString
        let textureAgeValue = NSNumber(value: textureAge)
        let options = [textureAgeKey: textureAgeValue] as NSDictionary
        
        var videoTextureCache: CVMetalTextureCache! = nil
        let status = CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                               options,
                                               self.device,
                                               nil,
                                               &videoTextureCache)
        if status != kCVReturnSuccess {
            throw MetalError.MTLContextError.textureCacheCreationFailed
        }
        
        return videoTextureCache
    }

}

public extension MTLTexture {

    func pixelBuffer(region: MTLRegion? = nil) throws -> CVPixelBuffer {
        guard let cvPixelFormat = self.pixelFormat
                                      .compatibleCVPixelFormat
        else { throw MetalError.MTLTextureError.imageIncompatiblePixelFormat }

        var pb: CVPixelBuffer? = nil
        var status = CVPixelBufferCreate(nil,
                                         region?.size.width ?? self.width,
                                         region?.size.height ?? self.height,
                                         cvPixelFormat,
                                         nil,
                                         &pb)
        guard status == kCVReturnSuccess,
              let pixelBuffer = pb
        else { throw MetalError.MTLTextureError.pixelBufferConversionFailed }

        status = CVPixelBufferLockBaseAddress(pixelBuffer, [])
        guard status == kCVReturnSuccess,
              let pixelBufferBaseAdress = CVPixelBufferGetBaseAddress(pixelBuffer)
        else { throw MetalError.MTLTextureError.pixelBufferConversionFailed }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        self.getBytes(pixelBufferBaseAdress,
                      bytesPerRow: bytesPerRow,
                      from: region ?? self.region,
                      mipmapLevel: 0)

        status = CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        guard status == kCVReturnSuccess
        else { throw MetalError.MTLTextureError.pixelBufferConversionFailed }

        return pixelBuffer
    }

}
