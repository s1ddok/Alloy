//
//  MTLContext+Device.swift
//  Alloy
//
//  Created by Eugene Bokhan on 27.11.2019.
//

import Metal

public extension MTLContext {

    // MARK: - Alloy API

    func maxTextureSize(desiredSize: MTLSize) -> MTLSize {
        return self.device
                   .maxTextureSize(desiredSize: desiredSize)
    }

    func compileShaderLibrary(from file: URL,
                              options: MTLCompileOptions? = nil) throws -> MTLLibrary {
        return try self.device
                       .compileShaderLibrary(from: file,
                                             options: options)
    }

    func createMultisampleRenderTargetPair(width: Int, height: Int,
                                           pixelFormat: MTLPixelFormat,
                                           sampleCount: Int = 4) throws -> (main: MTLTexture,
                                                                            resolve: MTLTexture) {
        return try self.device
                       .createMultisampleRenderTargetPair(width: width,
                                                          height: height,
                                                          pixelFormat: pixelFormat,
                                                          sampleCount: sampleCount)
    }

    func texture(width: Int,
                 height: Int,
                 pixelFormat: MTLPixelFormat,
                 usage: MTLTextureUsage = [.shaderRead]) throws -> MTLTexture {
        return try self.device
                       .texture(width: width,
                                height: height,
                                pixelFormat: pixelFormat,
                                usage: usage)
    }

    func depthState(depthCompareFunction: MTLCompareFunction,
                    isDepthWriteEnabled: Bool = true) throws -> MTLDepthStencilState {
        return try self.device
                       .depthState(depthCompareFunction: depthCompareFunction,
                                   isDepthWriteEnabled: isDepthWriteEnabled)
    }

    func depthBuffer(width: Int,
                     height: Int,
                     usage: MTLTextureUsage = [],
                     storageMode: MTLStorageMode? = nil) throws -> MTLTexture {
        return try self.device
                       .depthBuffer(width: width,
                                    height: height,
                                    usage: usage,
                                    storageMode: storageMode)
    }

    func buffer<T>(for type: T.Type,
                   count: Int = 1,
                   options: MTLResourceOptions) throws -> MTLBuffer {
        return try self.device
                       .buffer(for: type,
                               count: count,
                               options: options)
    }

    func heap(size: Int,
              storageMode: MTLStorageMode,
              cpuCacheMode: MTLCPUCacheMode = .defaultCache) throws -> MTLHeap {
        return try self.device
                       .heap(size: size,
                             storageMode: storageMode,
                             cpuCacheMode: cpuCacheMode)
    }

    // MARK: - Vanilla API

    var maxThreadgroupMemoryLength: Int {
        self.device
            .maxThreadgroupMemoryLength
    }

    @available(iOS 12.0, macOS 10.14, *)
    var maxArgumentBufferSamplerCount: Int {
        self.device
            .maxArgumentBufferSamplerCount
    }

    var areProgrammableSamplePositionsSupported: Bool {
        self.device
            .areProgrammableSamplePositionsSupported
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 13.0, *)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    var sparseTileSizeInBytes: Int {
        self.device
            .sparseTileSizeInBytes
    }
    #endif

    @available(iOS 12.0, macOS 10.14, *)
    var maxBufferLength: Int {
        self.device
            .maxBufferLength
    }

    var deviceName: String {
        return self.device
                   .name
    }

    var registryID: UInt64 {
        return self.device
                   .registryID
    }

    var maxThreadsPerThreadgroup: MTLSize {
        return self.device
                   .maxThreadsPerThreadgroup
    }

    @available(iOS 13.0, macOS 10.15, *)
    var hasUnifiedMemory: Bool {
        return self.device
                   .hasUnifiedMemory
    }

    var readWriteTextureSupport: MTLReadWriteTextureTier {
        return self.device
                   .readWriteTextureSupport
    }

    var argumentBuffersSupport: MTLArgumentBuffersTier {
        return self.device
                   .argumentBuffersSupport
    }

    var areRasterOrderGroupsSupported: Bool {
        return self.device
                   .areRasterOrderGroupsSupported
    }

    var currentAllocatedSize: Int {
        return self.device
                   .currentAllocatedSize
    }

    func makeCommandQueue() -> MTLCommandQueue? {
        return self.device
                   .makeCommandQueue()
    }

    func makeCommandQueue(maxCommandBufferCount: Int) -> MTLCommandQueue? {
        return self.device
                   .makeCommandQueue(maxCommandBufferCount: maxCommandBufferCount)
    }

    func heapTextureSizeAndAlign(descriptor desc: MTLTextureDescriptor) -> MTLSizeAndAlign {
        return self.device
                   .heapTextureSizeAndAlign(descriptor: desc)
    }

    func heapBufferSizeAndAlign(length: Int,
                                options: MTLResourceOptions = []) -> MTLSizeAndAlign {
        return self.device
                   .heapBufferSizeAndAlign(length: length,
                                           options: options)
    }

    func makeHeap(descriptor: MTLHeapDescriptor) -> MTLHeap? {
        return self.device
                   .makeHeap(descriptor: descriptor)
    }

    func makeBuffer(length: Int,
                    options: MTLResourceOptions = []) -> MTLBuffer? {
        return self.device
                   .makeBuffer(length: length,
                               options: options)
    }

    func makeBuffer(bytes pointer: UnsafeRawPointer,
                    length: Int,
                    options: MTLResourceOptions = []) -> MTLBuffer? {
        return self.device
                   .makeBuffer(bytes: pointer,
                               length: length,
                               options: options)
    }

    func makeBuffer(bytesNoCopy pointer: UnsafeMutableRawPointer,
                    length: Int,
                    options: MTLResourceOptions = [],
                    deallocator: ((UnsafeMutableRawPointer, Int) -> Void)? = nil) -> MTLBuffer? {
        return self.device
                   .makeBuffer(bytesNoCopy: pointer,
                               length: length,
                               options: options,
                               deallocator: deallocator)
    }

    func makeDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> MTLDepthStencilState? {
        return self.device.makeDepthStencilState(descriptor: descriptor)
    }

    func makeTexture(descriptor: MTLTextureDescriptor) -> MTLTexture? {
        return self.device
                   .makeTexture(descriptor: descriptor)
    }

    func makeTexture(descriptor: MTLTextureDescriptor,
                     iosurface: IOSurfaceRef,
                     plane: Int) -> MTLTexture? {
        return self.device
                   .makeTexture(descriptor: descriptor,
                                iosurface: iosurface,
                                plane: plane)
    }

    #if !targetEnvironment(simulator)
    // Probably it's a bug, but simulator's version of `MTLDevice`
    // doesn't know about `makeSharedTexture`.
    @available(iOS 13.0, macOS 10.14, *)
    func makeSharedTexture(descriptor: MTLTextureDescriptor) -> MTLTexture? {
        return self.device
                   .makeSharedTexture(descriptor: descriptor)
    }

    @available(iOS 13.0, macOS 10.14, *)
    func makeSharedTexture(handle sharedHandle: MTLSharedTextureHandle) -> MTLTexture? {
        return self.device
                   .makeSharedTexture(handle: sharedHandle)
    }
    #endif

    func makeSamplerState(descriptor: MTLSamplerDescriptor) -> MTLSamplerState? {
        return self.device
                   .makeSamplerState(descriptor: descriptor)
    }

    func makeDefaultLibrary() -> MTLLibrary? {
        return self.device
                   .makeDefaultLibrary()
    }

    func makeDefaultLibrary(bundle: Bundle) throws -> MTLLibrary {
        return try self.device
                       .makeDefaultLibrary(bundle: bundle)
    }

    func makeLibrary(filepath: String) throws -> MTLLibrary {
        return try self.device
                       .makeLibrary(filepath: filepath)
    }

    func makeLibrary(URL url: URL) throws -> MTLLibrary {
        return try self.device
                       .makeLibrary(URL: url)
    }

    func makeLibrary(data: __DispatchData) throws -> MTLLibrary {
        return try self.device
                       .makeLibrary(data: data)
    }

    func makeLibrary(source: String,
                     options: MTLCompileOptions?) throws -> MTLLibrary {
        return try self.device
                       .makeLibrary(source: source,
                                    options: options)
    }

    func makeLibrary(source: String,
                     options: MTLCompileOptions?,
                     completionHandler: @escaping MTLNewLibraryCompletionHandler) {
        return self.device
                   .makeLibrary(source: source,
                                options: options,
                                completionHandler: completionHandler)
    }

    func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) throws -> MTLRenderPipelineState {
        return try self.device
                       .makeRenderPipelineState(descriptor: descriptor)
    }

    func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor,
                                 options: MTLPipelineOption,
                                 reflection: AutoreleasingUnsafeMutablePointer<MTLAutoreleasedRenderPipelineReflection?>?) throws -> MTLRenderPipelineState {
        return try self.device
                       .makeRenderPipelineState(descriptor: descriptor,
                                                options: options,
                                                reflection: reflection)
    }

    func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor,
                                 completionHandler: @escaping MTLNewRenderPipelineStateCompletionHandler) {
        return self.device
                   .makeRenderPipelineState(descriptor: descriptor,
                                            completionHandler: completionHandler)
    }

    func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor,
                                 options: MTLPipelineOption,
                                 completionHandler: @escaping MTLNewRenderPipelineStateWithReflectionCompletionHandler) {
        return self.device
                   .makeRenderPipelineState(descriptor: descriptor,
                                            options: options,
                                            completionHandler: completionHandler)
    }

    func makeComputePipelineState(function computeFunction: MTLFunction) throws -> MTLComputePipelineState {
        return try self.device
                       .makeComputePipelineState(function: computeFunction)
    }

    func makeComputePipelineState(function computeFunction: MTLFunction,
                                  options: MTLPipelineOption,
                                  reflection: AutoreleasingUnsafeMutablePointer<MTLAutoreleasedComputePipelineReflection?>?) throws -> MTLComputePipelineState {
        return try self.device
                       .makeComputePipelineState(function: computeFunction,
                                                 options: options,
                                                 reflection: reflection)
    }

    func makeComputePipelineState(function computeFunction: MTLFunction,
                                  completionHandler: @escaping MTLNewComputePipelineStateCompletionHandler) {
        return self.device
                   .makeComputePipelineState(function: computeFunction,
                                             completionHandler: completionHandler)
    }

    func makeComputePipelineState(function computeFunction: MTLFunction,
                                  options: MTLPipelineOption,
                                  completionHandler: @escaping MTLNewComputePipelineStateWithReflectionCompletionHandler) {
        return self.device
                   .makeComputePipelineState(function: computeFunction,
                                             options: options,
                                             completionHandler: completionHandler)
    }

    func makeComputePipelineState(descriptor: MTLComputePipelineDescriptor,
                                  options: MTLPipelineOption,
                                  reflection: AutoreleasingUnsafeMutablePointer<MTLAutoreleasedComputePipelineReflection?>?) throws -> MTLComputePipelineState {
        return try self.device
                       .makeComputePipelineState(descriptor: descriptor,
                                                 options: options,
                                                 reflection: reflection)
    }

    func makeComputePipelineState(descriptor: MTLComputePipelineDescriptor,
                                  options: MTLPipelineOption,
                                  completionHandler: @escaping MTLNewComputePipelineStateWithReflectionCompletionHandler) {
        self.device
            .makeComputePipelineState(descriptor: descriptor,
                                      options: options,
                                      completionHandler: completionHandler)
    }

    func makeFence() -> MTLFence? {
        return self.device
                   .makeFence()
    }

    func supportsFeatureSet(_ featureSet: MTLFeatureSet) -> Bool {
        return self.device
                   .supportsFeatureSet(featureSet)
    }

    @available(iOS 13.0, macOS 10.15, *)
    func supportsFamily(_ gpuFamily: MTLGPUFamily) -> Bool {
        return self.device
                   .supportsFamily(gpuFamily)
    }

    func supportsTextureSampleCount(_ sampleCount: Int) -> Bool {
        return self.device
                   .supportsTextureSampleCount(sampleCount)
    }

    func minimumLinearTextureAlignment(for format: MTLPixelFormat) -> Int {
        return self.device
                   .minimumLinearTextureAlignment(for: format)
    }

    @available(iOS 12.0, macOS 10.14, *)
    func minimumTextureBufferAlignment(for format: MTLPixelFormat) -> Int {
        return self.device
                   .minimumTextureBufferAlignment(for: format)
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func makeRenderPipelineState(tileDescriptor descriptor: MTLTileRenderPipelineDescriptor,
                                 options: MTLPipelineOption,
                                 reflection: AutoreleasingUnsafeMutablePointer<MTLAutoreleasedRenderPipelineReflection?>?) throws -> MTLRenderPipelineState {
        return try self.device
                       .makeRenderPipelineState(tileDescriptor: descriptor,
                                                options: options,
                                                reflection: reflection)
    }

    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func makeRenderPipelineState(tileDescriptor descriptor: MTLTileRenderPipelineDescriptor,
                                 options: MTLPipelineOption,
                                 completionHandler: @escaping MTLNewRenderPipelineStateWithReflectionCompletionHandler) {
        self.device
            .makeRenderPipelineState(tileDescriptor: descriptor,
                                     options: options,
                                     completionHandler: completionHandler)
    }
    #endif

    func __getDefaultSamplePositions(_ positions: UnsafeMutablePointer<MTLSamplePosition>,
                                     count: Int) {
        self.device
            .__getDefaultSamplePositions(positions,
                                         count: count)
    }

    func makeArgumentEncoder(arguments: [MTLArgumentDescriptor]) -> MTLArgumentEncoder? {
        return self.device
                   .makeArgumentEncoder(arguments: arguments)
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 13.0, *)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func supportsRasterizationRateMap(layerCount: Int) -> Bool {
        return self.device
                   .supportsRasterizationRateMap(layerCount: layerCount)
    }

    @available(iOS 13.0, *)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func makeRasterizationRateMap(descriptor: MTLRasterizationRateMapDescriptor) -> MTLRasterizationRateMap? {
        return self.device
                   .makeRasterizationRateMap(descriptor: descriptor)
    }
    #endif

    @available(iOS 12.0, macOS 10.14, *)
    func makeIndirectCommandBuffer(descriptor: MTLIndirectCommandBufferDescriptor,
                                   maxCommandCount maxCount: Int,
                                   options: MTLResourceOptions = []) -> MTLIndirectCommandBuffer? {
        return self.device
                   .makeIndirectCommandBuffer(descriptor: descriptor,
                                              maxCommandCount: maxCount,
                                              options: options)
    }

    @available(iOS 12.0, macOS 10.14, *)
    func makeEvent() -> MTLEvent? {
        return self.device
                   .makeEvent()
    }

    @available(iOS 12.0, macOS 10.14, *)
    func makeSharedEvent() -> MTLSharedEvent? {
        return self.device
                   .makeSharedEvent()
    }

    @available(iOS 12.0, macOS 10.14, *)
    func makeSharedEvent(handle sharedEventHandle: MTLSharedEventHandle) -> MTLSharedEvent? {
        return self.device
                   .makeSharedEvent(handle: sharedEventHandle)
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 13.0, *)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func sparseTileSize(with textureType: MTLTextureType,
                        pixelFormat: MTLPixelFormat,
                        sampleCount: Int) -> MTLSize {
        return self.device
                   .sparseTileSize(with: textureType,
                                   pixelFormat: pixelFormat,
                                   sampleCount: sampleCount)
    }

    @available(iOS 13.0, *)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func supportsVertexAmplificationCount(_ count: Int) -> Bool {
        return self.device
                   .supportsVertexAmplificationCount(count)
    }
    #endif

    func getDefaultSamplePositions(sampleCount: Int) -> [MTLSamplePosition] {
        return self.device
                   .getDefaultSamplePositions(sampleCount: sampleCount)
    }

}
