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
    #if os(iOS)
    public typealias XImage = UIImage
    #elseif os(macOS)
    public typealias XImage = NSImage
    #endif
    
    public var cgImage: CGImage? {
        if self.pixelFormat == .bgra8Unorm {
            // read texture as byte array
            let rowBytes = self.width * 4
            let length = rowBytes * self.height
            let bgraBytes = [UInt8](repeating: 0, count: length)
            let region = MTLRegionMake2D(0, 0, self.width, self.height)
            self.getBytes(UnsafeMutableRawPointer(mutating: bgraBytes), bytesPerRow: rowBytes, from: region, mipmapLevel: 0)
            
            // use Accelerate framework to convert from BGRA to RGBA
            var bgraBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: bgraBytes),
                                           height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
            let rgbaBytes = [UInt8](repeating: 0, count: length)
            var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
                                           height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
            let map: [UInt8] = [2, 1, 0, 3]
            vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)
            
            // create CGImage with RGBA Flipped Bytes
            let colorScape = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            guard let data = CFDataCreate(nil, rgbaBytes, length) else { return nil }
            guard let dataProvider = CGDataProvider(data: data) else { return nil }
            let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
                                  space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
                                  decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            return cgImage
            
        } else if self.pixelFormat == .rgba8Unorm {
            let rowBytes = self.width * 4
            let length = rowBytes * self.height
            
            let rgbaBytes = [UInt8](repeating: 0, count: length)
            self.getBytes(UnsafeMutableRawPointer(mutating: rgbaBytes), bytesPerRow: rowBytes, from: region, mipmapLevel: 0)
            // create CGImage with RGBA Flipped Bytes
            let colorScape = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            guard let data = CFDataCreate(nil, rgbaBytes, length) else { return nil }
            guard let dataProvider = CGDataProvider(data: data) else { return nil }
            let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
                                  space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
                                  decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            return cgImage
        } else {
            return nil
        }
    }
    
    public var image: XImage? {
        guard let cgImage = self.cgImage else { return nil }
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        #endif
    }
}

public extension MTLTexture {
    public var region: MTLRegion {
        return MTLRegion(origin: .zero,
                         size: self.size)
    }
    
    public var size: MTLSize {
        return MTLSize(width: self.width,
                       height: self.height,
                       depth: self.depth)
    }
    
    public var descriptor: MTLTextureDescriptor {
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
        if #available(iOS 12, *) {
            retVal.allowGPUOptimizedContents = allowGPUOptimizedContents
        }
        
        return retVal
    }
    
    public func matchingTexture(usage: MTLTextureUsage? = nil,
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
}
