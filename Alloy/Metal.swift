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
    
    #if os(macOS)
    @available(OSX 10.11, *)
    public static let lowPowerDevice: MTLDevice? = {
        return MTLCopyAllDevices().first { $0.isLowPower }
    }()
    #endif
    
    public static var isAvailable: Bool {
        return Metal.device != nil
    }
    
}

public final class MTLContext {
    public enum Errors: Error {
        case commandBufferCreationFailed
    }

    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let standardLibrary: MTLLibrary?
    
    private var libraryCache: [Bundle: MTLLibrary] = [:]
    private lazy var textureLoader = MTKTextureLoader(device: self.device)
    private let textureDescriptor = MTLTextureDescriptor()
    
    public convenience init() {
        self.init(device: Metal.device)
    }
    
    public init(device: MTLDevice, commandQueue: MTLCommandQueue, library: MTLLibrary? = nil) {
        self.device = device
        self.commandQueue = commandQueue
        self.standardLibrary = library
    }
    
    public convenience init(device: MTLDevice, bundle: Bundle = .main, name: String? = nil) {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create a command queue to form a Metal context")
        }
        
        let library: MTLLibrary?
        
        if name == nil {
            if #available(OSX 10.12, *) {
                library = try? device.makeDefaultLibrary(bundle: bundle)
            } else {
                library = device.makeDefaultLibrary()
            }
        } else {
            library = try? device.makeLibrary(filepath: bundle.path(forResource: name!, ofType: "metallib")!)
        }

        self.init(device: device, commandQueue: commandQueue, library: library)
    }
    
    @available(iOS 10.0, macOS 10.12, *)
    public func shaderLibrary(for anyclass: AnyClass) -> MTLLibrary? {
        return self.shaderLibrary(for: Bundle(for: anyclass))
    }
    
    @available(iOS 10.0, macOS 10.12, *)
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
    
    public func scheduleAndWait<T>(_ bufferEncodings: (MTLCommandBuffer) throws -> T) throws -> T {
        guard let commandBuffer = self.commandQueue.makeCommandBuffer()
        else { throw Errors.commandBufferCreationFailed }
        
        let retVal = try bufferEncodings(commandBuffer)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return retVal
    }
    
    public func schedule(_ bufferEncodings: (MTLCommandBuffer) throws -> Void) throws {
        guard let commandBuffer = self.commandQueue.makeCommandBuffer()
        else { throw Errors.commandBufferCreationFailed }
        
        try bufferEncodings(commandBuffer)
        
        commandBuffer.commit()
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
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        sampleDesc.storageMode = .memoryless
        #endif
        sampleDesc.usage = .renderTarget
        
        guard let mainTex = device.makeTexture(descriptor: mainDesc),
              let sampleTex = device.makeTexture(descriptor: sampleDesc)
        else { return nil}
        
        return (main: sampleTex, resolve: mainTex)
    }
    
    public func texture(from image: CGImage, usage: MTLTextureUsage = [.shaderRead]) throws -> MTLTexture {
        let options: [MTKTextureLoader.Option: Any] = [
            // Note: the SRGB option should be set to false, otherwise the image
            // appears way too dark, since it wasn't actually saved as SRGB.
            .SRGB : false, // image.colorSpace == CGColorSpace(name: CGColorSpace.sRGB)
            .textureUsage: NSNumber(value: usage.rawValue)
        ]
        
        return try self.textureLoader
                       .newTexture(cgImage: image,
                                   options: options)
    }
    
    public func texture(width: Int,
                        height: Int,
                        pixelFormat: MTLPixelFormat,
                        usage: MTLTextureUsage = [.shaderRead]) -> MTLTexture? {
        self.textureDescriptor.width = width
        self.textureDescriptor.height = height
        self.textureDescriptor.pixelFormat = pixelFormat
        self.textureDescriptor.usage = usage
        
        return device.makeTexture(descriptor: textureDescriptor)
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
                            storageMode: MTLStorageMode? = nil) -> MTLTexture! {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.pixelFormat = .depth32Float
        textureDescriptor.usage = usage.union([.renderTarget])
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        textureDescriptor.storageMode = storageMode ?? .memoryless
        #else
        textureDescriptor.storageMode = storageMode ?? .private
        #endif
        
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        return texture
    }
    
    public func buffer<T>(for type: T.Type,
                          count: Int = 1,
                          options: MTLResourceOptions) -> MTLBuffer! {
        return self.device.makeBuffer(length: MemoryLayout<T>.stride * count,
                                      options: options)
    }
    
    @available(iOS 10.0, macOS 10.13, *)
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
