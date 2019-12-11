//
//  MTLDevice+Extensions.swift
//  Alloy
//
//  Created by Vladimir Pavlov on 06/05/2019.
//

import Metal

public extension MTLDevice {

    func compileShaderLibrary(from file: URL,
                              options: MTLCompileOptions? = nil) throws -> MTLLibrary {
        let shaderSource = try String(contentsOf: file)
        return try self.makeLibrary(source: shaderSource,
                                    options: options)
    }

    func createMultisampleRenderTargetPair(width: Int, height: Int,
                                           pixelFormat: MTLPixelFormat,
                                           sampleCount: Int = 4) -> (main: MTLTexture, resolve: MTLTexture)? {
        let mainDescriptor = MTLTextureDescriptor()
        mainDescriptor.width = width
        mainDescriptor.height = height
        mainDescriptor.pixelFormat = pixelFormat
        mainDescriptor.usage = [.renderTarget, .shaderRead]

        let sampleDescriptor = MTLTextureDescriptor()
        sampleDescriptor.textureType = MTLTextureType.type2DMultisample
        sampleDescriptor.width = width
        sampleDescriptor.height = height
        sampleDescriptor.sampleCount = sampleCount
        sampleDescriptor.pixelFormat = pixelFormat
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        sampleDescriptor.storageMode = .memoryless
        #endif
        sampleDescriptor.usage = .renderTarget

        guard let mainTex = self.makeTexture(descriptor: mainDescriptor),
              let sampleTex = self.makeTexture(descriptor: sampleDescriptor)
        else { return nil}

        return (main: sampleTex, resolve: mainTex)
    }

    func heap(size: Int,
              storageMode: MTLStorageMode,
              cpuCacheMode: MTLCPUCacheMode = .defaultCache) -> MTLHeap! {
        let descriptor = MTLHeapDescriptor()
        descriptor.size = size
        descriptor.storageMode = storageMode
        descriptor.cpuCacheMode = cpuCacheMode

        return self.makeHeap(descriptor: descriptor)
    }

    func buffer<T>(for type: T.Type,
                   count: Int = 1,
                   options: MTLResourceOptions) -> MTLBuffer! {
        return self.makeBuffer(length: MemoryLayout<T>.stride * count,
                               options: options)
    }

    func depthBuffer(width: Int, height: Int,
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
        return self.makeTexture(descriptor: textureDescriptor)
    }

    func depthState(depthCompareFunction: MTLCompareFunction,
                    isDepthWriteEnabled: Bool = true) -> MTLDepthStencilState! {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = depthCompareFunction
        descriptor.isDepthWriteEnabled = isDepthWriteEnabled
        return self.makeDepthStencilState(descriptor: descriptor)
    }

    func texture(width: Int,
                 height: Int,
                 pixelFormat: MTLPixelFormat,
                 usage: MTLTextureUsage = [.shaderRead]) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.usage = usage
        return self.makeTexture(descriptor: textureDescriptor)
    }

    func maxTextureSize(desiredSize: MTLSize) -> MTLSize {
        let maxSide: Int
        if self.supportsOnly8K() {
            maxSide = 8192
        } else {
            maxSide = 16_384
        }

        guard desiredSize.width > 0,
              desiredSize.height > 0
        else { return .zero }

        let aspectRatio = Float(desiredSize.width) / Float(desiredSize.height)
        if aspectRatio > 1 {
            let resultWidth = min(desiredSize.width, maxSide)
            let resultHeight = Float(resultWidth) / aspectRatio
            return MTLSize(width: resultWidth, height: Int(resultHeight.rounded()), depth: 0)
        } else {
            let resultHeight = min(desiredSize.height, maxSide)
            let resultWidth = Float(resultHeight) * aspectRatio
            return MTLSize(width: Int(resultWidth.rounded()), height: resultHeight, depth: 0)
        }
    }

    private func supportsOnly8K() -> Bool {
        #if targetEnvironment(macCatalyst)
        return !self.supportsFamily(.apple3)
        #elseif os(macOS)
        return false
        #else
        if #available(iOS 13.0, *) {
            return !self.supportsFamily(.apple3)
        } else {
            return !self.supportsFeatureSet(.iOS_GPUFamily3_v3)
        }
        #endif
    }
}
