import Metal

public extension MTLComputeCommandEncoder {
    
    func setValue<T>(_ value: T, at index: Int) {
        var t = value
        self.setBytes(&t, length: MemoryLayout<T>.stride, index: index)
    }
    
    func setValue<T>(_ value: [T], at index: Int) {
        var t = value
        self.setBytes(&t, length: MemoryLayout<T>.stride * value.count, index: index)
    }
    
    func setTextures(_ textures: [MTLTexture?], startingAt startIndex: Int = 0) {
        self.setTextures(textures, range: startIndex..<(startIndex + textures.count))
    }
    
    func setBuffers(_ buffers: [MTLBuffer?], offsets: [Int]? = nil, startingAt startIndex: Int = 0) {
        self.setBuffers(buffers,
                        offsets: offsets ?? buffers.map { _ in 0 },
                        range: startIndex..<(startIndex + buffers.count))
    }
    
    func setTextures(_ textures: MTLTexture?..., startingAt startIndex: Int = 0) {
        self.setTextures(textures, range: startIndex..<(startIndex + textures.count))
    }
    
    func setBuffers(_ buffers: MTLBuffer?..., offsets: [Int]? = nil, startingAt startIndex: Int = 0) {
        self.setBuffers(buffers,
                        offsets: offsets ?? buffers.map { _ in 0 },
                        range: startIndex..<(startIndex + buffers.count))
    }
    
    func dispatch1d(state: MTLComputePipelineState,
                    covering size: Int,
                    threadgroupWidth: Int? = nil) {
        let tgWidth = threadgroupWidth ?? state.threadExecutionWidth
        let tgSize = MTLSize(width: tgWidth, height: 1, depth: 1)
        
        let count = MTLSize(width: (size + tgWidth - 1) / tgWidth,
                            height: 1,
                            depth: 1)
        
        self.setComputePipelineState(state)
        self.dispatchThreadgroups(count, threadsPerThreadgroup: tgSize)
    }
    
    func dispatch2d(state: MTLComputePipelineState,
                    covering size: MTLSize,
                    threadgroupSize: MTLSize? = nil) {
        let tgSize = threadgroupSize ?? state.max2dThreadgroupSize
        
        let count = MTLSize(width: (size.width + tgSize.width - 1) / tgSize.width,
                            height: (size.height + tgSize.height - 1) / tgSize.height,
                            depth: 1)
        
        self.setComputePipelineState(state)
        self.dispatchThreadgroups(count, threadsPerThreadgroup: tgSize)
    }

    func dispatch1d(state: MTLComputePipelineState,
                    exactly size: Int,
                    threadgroupWidth: Int? = nil) {
        let tgSize = MTLSize(width: threadgroupWidth ?? state.threadExecutionWidth,
                             height: 1,
                             depth: 1)

        self.setComputePipelineState(state)
        self.dispatchThreads(MTLSize(width: size, height: 1, depth: 1),
                             threadsPerThreadgroup: tgSize)
    }
    
    func dispatch2d(state: MTLComputePipelineState,
                    exactly size: MTLSize,
                    threadgroupSize: MTLSize? = nil) {
        let tgSize = threadgroupSize ?? state.max2dThreadgroupSize
        
        self.setComputePipelineState(state)
        self.dispatchThreads(size, threadsPerThreadgroup: tgSize)
    }
}
