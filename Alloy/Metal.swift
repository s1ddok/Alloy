//
//  Metal.swift
//  LowPoly
//
//  Created by Andrey Volodin on 13.05.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import Metal
import MetalKit

public final class Metal {
    
    public static let device: MTLDevice! = MTLCreateSystemDefaultDevice()
    
    public static var isAvailable: Bool {
        return Metal.device != nil
    }
    
}

public final class MTLContext {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let standardLibrary: MTLLibrary
    
    private var libraryCache: [Bundle: MTLLibrary] = [:]
    
    public init(device: MTLDevice, commandQueue: MTLCommandQueue, library: MTLLibrary) {
        self.device = device
        self.commandQueue = commandQueue
        self.standardLibrary = library
    }
    
    public convenience init(device: MTLDevice, bundle: Bundle = .main, name: String? = nil) {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create a command queue to form a Metal context")
        }
        
        let library: MTLLibrary
        
        if name == nil {
            guard let lib = try? device.makeDefaultLibrary(bundle: bundle) else {
                fatalError("Could not load library to form a Metal context")
            }
            library = lib
        } else {
            guard let lib = try? device.makeLibrary(filepath: bundle.path(forResource: name!, ofType: "metallib")!) else {
                fatalError("Could not load library to form a Metal context")
            }
            library = lib
        }

        self.init(device: device, commandQueue: commandQueue, library: library)
    }
    
    public func shaderLibrary(for anyclass: AnyClass) -> MTLLibrary? {
        return self.shaderLibrary(for: Bundle(for: anyclass))
    }
    
    public func shaderLibrary(for bundle: Bundle) -> MTLLibrary? {
        if let cachedLibrary = self.libraryCache[bundle] {
            return cachedLibrary
        }
        
        guard let library = try? self.device.makeDefaultLibrary(bundle: bundle)
        else { return nil }
        
        self.libraryCache[bundle] = library
        return library
    }
    
    public func purgeLibraryCache() {
        self.libraryCache = [:]
    }
    
    public func compileShaderLibrary(from file: URL) throws -> MTLLibrary {
        let shaderSource = try String(contentsOf: file)
        
        return try device.makeLibrary(source: shaderSource, options: nil)
    }
    
    public func createMultisampleRenderTargetPair(width: Int, height: Int,
                                                  pixelFormat: MTLPixelFormat,
                                                  sampleCount: Int = 4) -> (main: MTLTexture, resolve: MTLTexture)? {
        let mainDesc = MTLTextureDescriptor()
        mainDesc.width = width
        mainDesc.height = height
        mainDesc.pixelFormat = pixelFormat
        mainDesc.usage = [.renderTarget, .shaderRead]
        
        let sampleDesc = MTLTextureDescriptor()
        sampleDesc.textureType = MTLTextureType.type2DMultisample
        sampleDesc.width  = width
        sampleDesc.height = height
        sampleDesc.sampleCount = sampleCount
        sampleDesc.pixelFormat = pixelFormat
        sampleDesc.storageMode = .memoryless
        sampleDesc.usage = .renderTarget
        
        guard let mainTex = device.makeTexture(descriptor: mainDesc),
              let sampleTex = device.makeTexture(descriptor: sampleDesc)
        else { return nil}
        
        return (main: sampleTex, resolve: mainTex)
    }
    
    public func createRenderTargetTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat, writable: Bool = false) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.width  = width
        textureDescriptor.height = height
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        if writable {
            textureDescriptor.usage.formUnion(.shaderWrite)
        }
        let outTexture = device.makeTexture(descriptor: textureDescriptor)!
        return outTexture
    }
    
    public func texture(from image: UIImage) -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: device)
        // Note: the SRGB option should be set to false, otherwise the image
        // appears way too dark, since it wasn't actually saved as SRGB.
        
        return try! textureLoader.newTexture(cgImage: image.cgImage!,
                                             options: [ .SRGB : false ])
                                                //image.cgImage!.colorSpace!.name == CGColorSpace.sRGB ])
    }
    
    public func texture(width: Int, height: Int, pixelFormat: MTLPixelFormat, writable: Bool = false) -> MTLTexture! {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.usage = [.shaderRead]
        if writable {
            textureDescriptor.usage.formUnion(.shaderWrite)
        }
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        return texture
    }
    
    public func depthState(depthCompareFunction: MTLCompareFunction,
                           isDepthWriteEnabled: Bool = true) -> MTLDepthStencilState! {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = depthCompareFunction
        descriptor.isDepthWriteEnabled = isDepthWriteEnabled
        
        return self.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    public func depthBuffer(width: Int, height: Int,
                            usage: MTLTextureUsage = [],
                            storageMode: MTLStorageMode = .memoryless) -> MTLTexture! {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.pixelFormat = .depth32Float
        textureDescriptor.usage = usage.union([.renderTarget])
        textureDescriptor.storageMode = storageMode
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        return texture
    }
    
    public func buffer<T>(for type: T.Type,
                          options: MTLResourceOptions) -> MTLBuffer! {
        return self.device.makeBuffer(length: MemoryLayout<T>.stride,
                                      options: options)
    }
    
    public func heap(size: Int,
                     storageMode: MTLStorageMode,
                     cpuCacheMode: MTLCPUCacheMode = .defaultCache) -> MTLHeap! {
        let descriptor = MTLHeapDescriptor()
        descriptor.size = size
        descriptor.storageMode = storageMode
        descriptor.cpuCacheMode = cpuCacheMode
        
        let heap = device.makeHeap(descriptor: descriptor)
        return heap
    }
}
