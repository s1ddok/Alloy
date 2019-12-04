//
//  MTLLibrary+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 02/12/2018.
//

import Metal

public extension MTLLibrary {

    func function(named functionName: String) throws -> MTLFunction {
        guard let function = self.makeFunction(name: functionName)
        else { throw MetalError.MTLLibraryError.functionCreationFailed }
        return function
    }

    func computePipelineState(function functionName: String) throws -> MTLComputePipelineState {
        return try self.device
                       .makeComputePipelineState(function: self.function(named: functionName))
    }
    
    func computePipelineState(function: String,
                              constants: MTLFunctionConstantValues) throws -> MTLComputePipelineState {
        let function = try self.makeFunction(name: function,
                                             constantValues: constants)
        return try self.device
                       .makeComputePipelineState(function: function)
    }
}
