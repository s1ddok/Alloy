//
//  MTLComputeCommandEncoder+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 27/11/2018.
//

import Metal

public extension MTLComputeCommandEncoder {
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
