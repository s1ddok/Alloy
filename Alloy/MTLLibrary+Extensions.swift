//
//  MTLLibrary+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 02/12/2018.
//

import Metal

public extension MTLLibrary {

    func createFunction(name functionName: String) throws -> MTLFunction {
        guard let function = self.makeFunction(name: functionName)
        else { throw CommonErrors.metalInitializationFailed }
        return function
    }

    func computePipelineState(function functionName: String) throws -> MTLComputePipelineState {
        return try self.device
                       .makeComputePipelineState(function: self.createFunction(name: functionName))
    }
    
    @available(OSX 10.12, *)
    func computePipelineState(function: String,
                              constants: MTLFunctionConstantValues) throws -> MTLComputePipelineState {
        let function = try self.makeFunction(name: function,
                                             constantValues: constants)
        return try self.device
                       .makeComputePipelineState(function: function)
    }
}
