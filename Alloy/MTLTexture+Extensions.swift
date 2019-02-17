//
//  MTLTexture+Extensions.swift
//  AIBeauty
//
//  Created by Andrey Volodin on 24.09.2018.
//

import Foundation
import CoreGraphics
import MetalKit
import GLKit
import Accelerate

public extension MTLTexture {
    #if os(iOS) || os(tvOS)
    typealias XImage = UIImage
    #elseif os(macOS)
    typealias XImage = NSImage
    #endif
    
    var cgImage: CGImage? {
        #if os(macOS)
        guard self.storageMode == .managed || self.storageMode == .shared else {
            return nil
        }
        #endif

        #if os(iOS) || os(tvOS)
        guard self.storageMode == .shared else {
            return nil
        }
        #endif

        switch self.pixelFormat {
        case .a8Unorm, .r8Unorm, .r8Uint:
            let rowBytes = self.width
            let length = rowBytes * self.height

            let rgbaBytes = [UInt8](repeating: 0, count: length)
            self.getBytes(UnsafeMutableRawPointer(mutating: rgbaBytes),
                                                  bytesPerRow: rowBytes,
                                                  from: self.region,
                                                  mipmapLevel: 0)

            let colorScape = CGColorSpaceCreateDeviceGray()
            let bitmapInfo = CGBitmapInfo(rawValue: self.pixelFormat == .a8Unorm
                                                    ? CGImageAlphaInfo.alphaOnly.rawValue
                                                    : CGImageAlphaInfo.none.rawValue)
            guard let data = CFDataCreate(nil, rgbaBytes, length),
                  let dataProvider = CGDataProvider(data: data)
            else { return nil }
            let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: rowBytes,
                                  space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
                                  decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            return cgImage
        case .bgra8Unorm:
            // read texture as byte array
            let rowBytes = self.width * 4
            let length = rowBytes * self.height
            let bgraBytes = [UInt8](repeating: 0, count: length)
            self.getBytes(UnsafeMutableRawPointer(mutating: bgraBytes),
                                                  bytesPerRow: rowBytes,
                                                  from: self.region,
                                                  mipmapLevel: 0)

            // use Accelerate framework to convert from BGRA to RGBA
            var bgraBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: bgraBytes),
                                           height: vImagePixelCount(self.height),
                                           width: vImagePixelCount(self.width),
                                           rowBytes: rowBytes)
            let rgbaBytes = [UInt8](repeating: 0, count: length)
            var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
                                           height: vImagePixelCount(self.height),
                                           width: vImagePixelCount(self.width),
                                           rowBytes: rowBytes)
            let map: [UInt8] = [2, 1, 0, 3]
            vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)

            // create CGImage with RGBA Flipped Bytes
            let colorScape = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            guard let data = CFDataCreate(nil, rgbaBytes, length),
                  let dataProvider = CGDataProvider(data: data)
            else { return nil }
            let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
                                  space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
                                  decode: nil, shouldInterpolate: true, intent: .defaultIntent)

            return cgImage
        case .rgba8Unorm:
            let rowBytes = self.width * 4
            let length = rowBytes * self.height

            let rgbaBytes = [UInt8](repeating: 0, count: length)
            self.getBytes(UnsafeMutableRawPointer(mutating: rgbaBytes),
                          bytesPerRow: rowBytes,
                          from: self.region,
                          mipmapLevel: 0)

            let colorScape = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            guard let data = CFDataCreate(nil, rgbaBytes, length),
                  let dataProvider = CGDataProvider(data: data)
            else { return nil }
            let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
                                  space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
                                  decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            return cgImage
        default: return nil
        }
    }
    
    var image: XImage? {
        guard let cgImage = self.cgImage else { return nil }
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
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
                         storage: MTLStorageMode? = nil) -> MTLTexture? {
        let matchingDescriptor = self.descriptor
        
        if let u = usage {
            matchingDescriptor.usage = u
        }
        if let s = storage {
            matchingDescriptor.storageMode = s
        }
        
        return self.device.makeTexture(descriptor: matchingDescriptor)
    }
    
    func view(slice: Int, levels: Range<Int>? = nil) -> MTLTexture? {
        let sliceType: MTLTextureType
        
        switch self.textureType {
        case .type1DArray: sliceType = .type1D
        case .type2DArray: sliceType = .type2D
        case .typeCubeArray: sliceType = .typeCube
        default:
            guard slice == 0 else {
                return nil
            }
            
            sliceType = self.textureType
        }
        
        return self.makeTextureView(pixelFormat: self.pixelFormat,
                                    textureType: sliceType,
                                    levels: levels ?? 0..<1,
                                    slices: slice..<(slice + 1))
    }
}
