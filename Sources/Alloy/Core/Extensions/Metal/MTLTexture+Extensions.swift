import Foundation
import CoreGraphics
import MetalKit
import MetalPerformanceShaders
import Accelerate

public extension MTLTexture {
    #if os(iOS) || os(tvOS)
    typealias XImage = UIImage
    #elseif os(macOS)
    typealias XImage = NSImage
    #endif
    
    func cgImage(colorSpace: CGColorSpace? = nil) throws -> CGImage {
        guard self.isAccessibleOnCPU
        else { throw MetalError.MTLTextureError.imageCreationFailed }

        switch self.pixelFormat {
        case .a8Unorm, .r8Unorm, .r8Uint:
            let rowBytes = self.width
            let length = rowBytes * self.height

            let rgbaBytes = UnsafeMutableRawPointer.allocate(byteCount: length,
                                                             alignment: MemoryLayout<UInt8>.alignment)
            defer { rgbaBytes.deallocate() }
            self.getBytes(rgbaBytes,
                          bytesPerRow: rowBytes,
                          from: self.region,
                          mipmapLevel: 0)

            let colorScape = colorSpace ?? CGColorSpaceCreateDeviceGray()
            let bitmapInfo = CGBitmapInfo(rawValue: self.pixelFormat == .a8Unorm
                                                    ? CGImageAlphaInfo.alphaOnly.rawValue
                                                    : CGImageAlphaInfo.none.rawValue)
            guard let data = CFDataCreate(nil,
                                          rgbaBytes.assumingMemoryBound(to: UInt8.self),
                                          length),
                  let dataProvider = CGDataProvider(data: data),
                  let cgImage = CGImage(width: self.width,
                                        height: self.height,
                                        bitsPerComponent: 8,
                                        bitsPerPixel: 8,
                                        bytesPerRow: rowBytes,
                                        space: colorScape,
                                        bitmapInfo: bitmapInfo,
                                        provider: dataProvider,
                                        decode: nil,
                                        shouldInterpolate: true,
                                        intent: .defaultIntent)
            else { throw MetalError.MTLTextureError.imageCreationFailed }

            return cgImage
        case .rgba8Unorm, .rgba8Unorm_srgb, .bgra8Unorm, .bgra8Unorm_srgb:
            let rowBytes = self.width * 4
            let length = rowBytes * self.height

            let rgbaBytes = UnsafeMutableRawPointer.allocate(byteCount: length,
                                                             alignment: MemoryLayout<UInt8>.alignment)
            defer { rgbaBytes.deallocate() }

            self.getBytes(rgbaBytes,
                          bytesPerRow: rowBytes,
                          from: self.region,
                          mipmapLevel: 0)

            let colorScape = colorSpace ?? CGColorSpaceCreateDeviceRGB()

            let bitmapInfo: CGBitmapInfo
            if self.pixelFormat == .bgra8Unorm || self.pixelFormat == .bgra8Unorm_srgb {
                bitmapInfo = .init(rawValue: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
            } else {
                bitmapInfo = .init(rawValue: CGImageByteOrderInfo.order32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
            }

            guard let data = CFDataCreate(nil,
                                          rgbaBytes.assumingMemoryBound(to: UInt8.self),
                                          length),
                  let dataProvider = CGDataProvider(data: data),
                  let cgImage = CGImage(width: self.width,
                                        height: self.height,
                                        bitsPerComponent: 8,
                                        bitsPerPixel: 32,
                                        bytesPerRow: rowBytes,
                                        space: colorScape,
                                        bitmapInfo: bitmapInfo,
                                        provider: dataProvider,
                                        decode: nil,
                                        shouldInterpolate: true,
                                        intent: .defaultIntent)
            else { throw MetalError.MTLTextureError.imageCreationFailed }
            
            return cgImage
        default: throw MetalError.MTLTextureError.imageIncompatiblePixelFormat
        }
    }
    
    func image(colorSpace: CGColorSpace? = nil) throws -> XImage {
        let cgImage = try self.cgImage(colorSpace: colorSpace)
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage,
                       size: CGSize(width: cgImage.width,
                                    height: cgImage.height))
        #endif
    }
}

public extension MTLTexture {
    var region: MTLRegion {
        return MTLRegion(origin: .zero,
                         size: self.size)
    }
    
    var size: MTLSize {
        return MTLSize(width: self.width,
                       height: self.height,
                       depth: self.depth)
    }
    
    var descriptor: MTLTextureDescriptor {
        let retVal = MTLTextureDescriptor()
        
        retVal.width = width
        retVal.height = height
        retVal.depth = depth
        retVal.arrayLength = arrayLength
        retVal.storageMode = storageMode
        retVal.cpuCacheMode = cpuCacheMode
        retVal.usage = usage
        retVal.textureType = textureType
        retVal.sampleCount = sampleCount
        retVal.mipmapLevelCount = mipmapLevelCount
        retVal.pixelFormat = pixelFormat
        if #available(iOS 12, macOS 10.14, *) {
            retVal.allowGPUOptimizedContents = allowGPUOptimizedContents
        }
        
        return retVal
    }
    
    func matchingTexture(usage: MTLTextureUsage? = nil,
                         storage: MTLStorageMode? = nil) throws -> MTLTexture {
        let matchingDescriptor = self.descriptor
        
        if let u = usage {
            matchingDescriptor.usage = u
        }
        if let s = storage {
            matchingDescriptor.storageMode = s
        }

        guard let matchingTexture = self.device.makeTexture(descriptor: matchingDescriptor)
        else { throw MetalError.MTLDeviceError.textureCreationFailed }
        
        return matchingTexture
    }
    
    func matchingTemporaryImage(commandBuffer: MTLCommandBuffer,
                                usage: MTLTextureUsage? = nil) -> MPSTemporaryImage {
        let matchingDescriptor = self.descriptor
        
        if let u = usage {
            matchingDescriptor.usage = u
        }
        // it has to be enforced for temporary image
        matchingDescriptor.storageMode = .private
        
        return MPSTemporaryImage(commandBuffer: commandBuffer, textureDescriptor: matchingDescriptor)
    }
    
    func view(slice: Int,
              levels: Range<Int>? = nil) -> MTLTexture? {
        let sliceType: MTLTextureType
        
        switch self.textureType {
        case .type1DArray: sliceType = .type1D
        case .type2DArray: sliceType = .type2D
        case .typeCubeArray: sliceType = .typeCube
        default:
            guard slice == 0
            else { return nil }
            sliceType = self.textureType
        }

        return self.makeTextureView(pixelFormat: self.pixelFormat,
                                    textureType: sliceType,
                                    levels: levels ?? 0..<1,
                                    slices: slice..<(slice + 1))
    }

    func view(level: Int) -> MTLTexture? {
        let levels = level ..< (level + 1)
        return self.view(slice: 0,
                         levels: levels)
    }
}

/* Utility functions for converting of MTLTextures to floating point arrays. */

public extension MTLTexture {

    /// Creates a new array of `Float`s and copies the texture's pixels into it.
    ///
    /// - Parameters:
    ///   - width: Width of the texture.
    ///   - height: Height of the texture.
    ///   - featureChannels: The number of color components per pixel: must be 1, 2, or 4.
    /// - Returns: Array of floats containing each pixel of the texture.
    func toFloatArray(width: Int,
                      height: Int,
                      featureChannels: Int) throws -> [Float] {
        return try self.toArray(width: width,
                                height: height,
                                featureChannels: featureChannels,
                                initial: .zero)
    }

    /// Creates a new array of `Float16`s and copies the texture's pixels into it.
    ///
    /// - Parameters:
    ///   - width: Width of the texture.
    ///   - height: Height of the texture.
    ///   - featureChannels: The number of color components per pixel: must be 1, 2, or 4.
    /// - Returns: Array of floats containing each pixel of the texture.
    func toFloat16Array(width: Int,
                        height: Int,
                        featureChannels: Int) throws -> [Float16] {
        return try self.toArray(width: width,
                                height: height,
                                featureChannels: featureChannels,
                                initial: .zero)
    }

    /// Creates a new array of `UInt8`s and copies the texture's pixels into it.
    ///
    /// - Parameters:
    ///   - width: Width of the texture.
    ///   - height: Height of the texture.
    ///   - featureChannels: The number of color components per pixel: must be 1, 2, or 4.
    /// - Returns: Array of floats containing each pixel of the texture.
    func toUInt8Array(width: Int,
                      height: Int,
                      featureChannels: Int) throws -> [UInt8] {
        return try self.toArray(width: width,
                                height: height,
                                featureChannels: featureChannels,
                                initial: .zero)
    }

    /// Convenience function that copies the texture's pixel data to a Swift array.
    ///
    /// - Parameters:
    ///   - width: Width of the texture.
    ///   - height: Height of the texture.
    ///   - featureChannels: The number of color components per pixel: must be 1, 2, or 4.
    ///   - initial: This parameter is necessary because we need to give the array
    ///     an initial value. Unfortunately, we can't do `[T](repeating: T(0), ...)`
    ///     since `T` could be anything and may not have an init that takes a literal
    ///     value.
    /// - Returns: Swift array containing texture's pixel data.

    private func toArray<T>(width: Int,
                            height: Int,
                            featureChannels: Int,
                            initial: T) throws -> [T] {
        guard self.isAccessibleOnCPU
           && featureChannels != 3
           && featureChannels <= 4
        else { throw MetalError.MTLTextureError.imageIncompatiblePixelFormat }

        let count = width
                  * height
                  * featureChannels
        var bytes = [T](repeating: initial,
                        count: count)
        let bytesPerRow = width
                        * featureChannels
                        * MemoryLayout<T>.stride
        self.getBytes(&bytes,
                      bytesPerRow: bytesPerRow,
                      from: .init(origin: .zero,
                                  size: .init(width: width,
                                              height: height,
                                              depth: 1)),
                      mipmapLevel: 0)
        return bytes
    }
}
