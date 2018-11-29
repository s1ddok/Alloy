//
//  MTLComputeCommandEncoder+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 27/11/2018.
//

import Metal

public extension MTLComputeCommandEncoder {
    
    public func set<T>(_ value: T, at index: Int) {
        var t = value
        self.setBytes(&t, length: MemoryLayout<T>.stride, index: index)
    }
    
    public func set<T>(_ value: T, at index: Int) where T: Collection {
        var t = value
        self.setBytes(&t, length: MemoryLayout<T>.stride * value.count, index: index)
    }
    
    public func dispatch1d(state: MTLComputePipelineState,
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
    
    public func dispatch2d(state: MTLComputePipelineState,
                           covering size: MTLSize,
                           threadgroupSize: MTLSize? = nil) {
        let tgSize = threadgroupSize ?? state.max2dThreadgroupSize
        
        let count = MTLSize(width: (size.width + tgSize.width - 1) / tgSize.width,
                            height: (size.height + tgSize.height - 1) / tgSize.height,
                            depth: 1)
        
        self.setComputePipelineState(state)
        self.dispatchThreadgroups(count, threadsPerThreadgroup: tgSize)
    }
}
