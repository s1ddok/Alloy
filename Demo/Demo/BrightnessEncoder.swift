//
//  BrightnessEncoder.swift
//  Demo
//
//  Created by Andrey Volodin on 27/12/2018.
//  Copyright © 2018 avolodin. All rights reserved.
//

import Alloy

public class BrightnessEncoder {
    public let context: MTLContext
    fileprivate let pipelineState: MTLComputePipelineState
    
    /**
     * This variable controls the brightness factor. Should be in range of -1.0...1.0
     */
    public var intensity: Float = 1.0
    
    public init(context: MTLContext) {
        self.context = context
        
        guard let lib = context.shaderLibrary(for: BrightnessEncoder.self),
              let state = try? lib.computePipelineState(function: "brightness")
        else { fatalError("Error during shader loading") }
        
        self.pipelineState = state
    }
    
    public func encode(input: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.set(textures: [input])
            encoder.set(self.intensity, at: 0)
            
            encoder.dispatch2d(state: self.pipelineState,
                               covering: input.size)
        }
    }
    
}
