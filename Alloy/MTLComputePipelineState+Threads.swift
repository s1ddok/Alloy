import Metal

public extension MTLComputePipelineState {
    var executionWidthThreadgroupSize: MTLSize {
        let w = self.threadExecutionWidth
        
        return MTLSize(width: w, height: 1, depth: 1)
    }
    
    var max1dThreadgroupSize: MTLSize {
        let w = self.maxTotalThreadsPerThreadgroup
        
        return MTLSize(width: w, height: 1, depth: 1)
    }
    
    var max2dThreadgroupSize: MTLSize {
        let w = self.threadExecutionWidth
        let h = self.maxTotalThreadsPerThreadgroup / w
    
        return MTLSize(width: w, height: h, depth: 1)
    }
}
