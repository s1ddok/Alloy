//
//  MTLLibrary+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 02/12/2018.
//

import Metal

public extension MTLLibrary {
    func computePipelineState(function: String) throws -> MTLComputePipelineState {
        guard let function = self.makeFunction(name: function)
        else { throw MetalErrors.MTLLibraryError.functionCreationFailed }
        
        return try self.device.makeComputePipelineState(function: function)
    }
    
    func computePipelineState(function: String,
                              constants: MTLFunctionConstantValues) throws -> MTLComputePipelineState {
        let function = try self.makeFunction(name: function,
                                             constantValues: constants)
        
        return try self.device.makeComputePipelineState(function: function)
    }
}
