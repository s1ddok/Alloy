//
//  MTLComputeCommandEncoder+Threads.swift
//  AlloyDemo
//
//  Created by Andrey Volodin on 28.08.2018.
//  Copyright © 2018 Andrey Volodin. All rights reserved.
//

import Metal

public extension MTLComputePipelineState {
    public var executionWidthThreadgroupSize: MTLSize {
        let w = self.threadExecutionWidth
        
        return MTLSize(width: w, height: 1, depth: 1)
    }
    
    public var max1dThreadgroupSize: MTLSize {
        let w = self.maxTotalThreadsPerThreadgroup
        
        return MTLSize(width: w, height: 1, depth: 1)
    }
    
    public var max2dThreadgroupSize: MTLSize {
        let w = self.threadExecutionWidth
        let h = self.maxTotalThreadsPerThreadgroup / w
    
        return MTLSize(width: w, height: h, depth: 1)
    }
}
