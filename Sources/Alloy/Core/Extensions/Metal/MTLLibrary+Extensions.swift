import Metal

public extension MTLLibrary {

    func computePipelineState(function functionName: String) throws -> MTLComputePipelineState {
        guard let function = self.makeFunction(name: functionName)
        else { throw MetalError.MTLLibraryError.functionCreationFailed }
        return try self.device
                       .makeComputePipelineState(function: function)
    }
    
    func computePipelineState(function: String,
                              constants: MTLFunctionConstantValues) throws -> MTLComputePipelineState {
        let function = try self.makeFunction(name: function,
                                             constantValues: constants)
        return try self.device
                       .makeComputePipelineState(function: function)
    }
}
