import Metal

@dynamicMemberLookup
public final class ComputeCommand {
    public typealias ThreadsInfo = (groupSize: MTLSize, groupCount: MTLSize)
    public typealias GridInfo = (gridSize: MTLSize, groupSize: MTLSize)
    
    public let pipelineState: MTLComputePipelineState
    
    fileprivate let threadgroupMemoryArguments: [String: MTLArgument]
    fileprivate let samplerArguments: [String: MTLArgument]
    fileprivate let textureArguments: [String: MTLArgument]
    fileprivate let bufferArguments: [String: MTLArgument]
    
    // MARK: Threadgroup Memory Lengths values
    fileprivate var threadgroupMemoryLengths: [String: Int] = [:]
    
    // MARK: Buffer values
    fileprivate var bufferValues: [String: MTLBuffer] = [:]
    fileprivate var bufferOffsetValues: [String: Int] = [:]
    
    // MARK: Texture values:
    fileprivate var textureValues: [String: MTLTexture] = [:]
    // TODO: Samplers are not supported yet
    // TODO: Sampler LoD clamping is not supported yet
    fileprivate var samplerValues: [String: MTLSamplerState] = [:]
    
    public init(library: MTLLibrary,
                name: String,
                constantValues: MTLFunctionConstantValues? = nil) throws {
        let function: MTLFunction
        if let consts = constantValues {
            function = try library.makeFunction(name: name,
                                                constantValues: consts)
        } else {
            guard let f = library.makeFunction(name: name) else {
                fatalError("Couldn't find function with name: \(name)")
            }
            
            function = f 
        }
        
        var reflection: MTLAutoreleasedComputePipelineReflection? = nil
        self.pipelineState = try library.device.makeComputePipelineState(function: function,
                                                                         options: .argumentInfo,
                                                                         reflection: &reflection)
        
        self.samplerArguments = reflection!.arguments.filter { $0.type == .sampler }.toDictionary { $0.name }
        self.textureArguments = reflection!.arguments.filter { $0.type == .texture }.toDictionary { $0.name }
        self.bufferArguments = reflection!.arguments.filter { $0.type == .buffer }.toDictionary { $0.name }
        self.threadgroupMemoryArguments = reflection!.arguments.filter { $0.type == .threadgroupMemory }.toDictionary { $0.name }
    }
    
    public subscript(dynamicMember input: String) -> MTLBuffer? {
        get { return self.bufferValues[input] }
        set { self.bufferValues[input] = newValue }
    }
    
    public subscript(dynamicMember input: String) -> MTLTexture? {
        get { return self.textureValues[input] }
        set { self.textureValues[input] = newValue }
    }
    
    public subscript(dynamicMember input: String) -> Int? {
        get {
            if input.hasSuffix(ComputeCommand.bufferOffsetPostFix)
            && input != ComputeCommand.bufferOffsetPostFix,
            let bufferOffset = self.bufferOffsetValues[input] {
                return bufferOffset
            } else {
                return self.threadgroupMemoryLengths[input]
            }
        }
        set {
            // Check if passed argument if buffer offset
            if input.hasSuffix(ComputeCommand.bufferOffsetPostFix)
            && input.count > ComputeCommand.bufferOffsetPostFix.count {
                let bufferName = String(input.dropLast(ComputeCommand.bufferOffsetPostFix.count))
                // if there are not such buffer, user tries to assign something else
                if let _ = self.bufferArguments[bufferName] {
                    self.bufferOffsetValues[bufferName] = newValue
                    return
                }
            }
            
            // Check if passed argument is threadgroup memory length
            if input.hasSuffix(ComputeCommand.threadgroupMemoryLengthPostFix)
            && input.count > ComputeCommand.threadgroupMemoryLengthPostFix.count {
                self.threadgroupMemoryLengths[input] = newValue
                
                let threadgroupArgumentName = String(input.dropLast(ComputeCommand.threadgroupMemoryLengthPostFix.count))
                // if there are not such threadgroup memory, user tries to assign something else
                if let _ = self.threadgroupMemoryArguments[threadgroupArgumentName] {
                    self.threadgroupMemoryLengths[threadgroupArgumentName] = newValue
                    return
                }
            }
            
            print("\(#function) WARNING: Trying to assign Int argument failed. Didn't find any matches for argument name: \(input)")
        }
    }
    
    public func encode(commandBuffer: MTLCommandBuffer, threadsInfo: @autoclosure () -> ThreadsInfo) {
        commandBuffer.compute { encoder in
            self.encode(using: encoder, threadsInfo: threadsInfo())
        }
    }
    
    public func encode(commandBuffer: MTLCommandBuffer, gridInfo: @autoclosure () -> GridInfo) {
        commandBuffer.compute { encoder in
            self.encode(using: encoder, gridInfo: gridInfo())
        }
    }
    
    public func encode(using encoder: MTLComputeCommandEncoder, threadsInfo: @autoclosure () -> ThreadsInfo) {
        self.setup(using: encoder)
        self.dispatch(using: encoder, threadsInfo: threadsInfo())
    }
    
    public func encode(using encoder: MTLComputeCommandEncoder, gridInfo: @autoclosure () -> GridInfo) {
        self.setup(using: encoder)
        self.dispatch(using: encoder, gridInfo: gridInfo())
    }
    
    fileprivate func setup(using encoder: MTLComputeCommandEncoder) {
        for (name, argument) in textureArguments {
            guard let texture = self.textureValues[name] else {
                fatalError("\(#function): Missing texture value for \(name) argument")
            }
            
            encoder.setTexture(texture, index: argument.index)
        }

        for (name, argument) in self.samplerArguments {
            guard let sampler = self.samplerValues[name] else {
                 fatalError("\(#function): Missing sampler value for \(name) argument")
            }

            encoder.setSamplerState(sampler, index: argument.index)
        }
        
        for (name, argument) in bufferArguments {
            guard let buffer = self.bufferValues[name] else {
                fatalError("\(#function): Missing buffer value for \(name) argument")
            }
            
            let offset = self.bufferOffsetValues[name] ?? 0
            
            encoder.setBuffer(buffer, offset: offset, index: argument.index)
        }
        
        for (name, argument) in threadgroupMemoryArguments {
            let length = self.threadgroupMemoryLengths[name] ?? 0
            if length <= 0 {
                print("\(#function): WARNING: Missing correct value for threadgroup memory argument \(name). Current value is \(length).")
                continue
            }
            
            encoder.setThreadgroupMemoryLength(length, index: argument.index)
        }
    }
    
    fileprivate func dispatch(using encoder: MTLComputeCommandEncoder,
                              threadsInfo: @autoclosure () -> ThreadsInfo) {
        let threadsInfo = threadsInfo()
        encoder.dispatchThreadgroups(threadsInfo.groupCount,
                                     threadsPerThreadgroup: threadsInfo.groupSize)
        
    }
    
    fileprivate func dispatch(using encoder: MTLComputeCommandEncoder,
                              gridInfo: @autoclosure () -> GridInfo) {
        let gridInfo = gridInfo()
        encoder.dispatchThreads(gridInfo.gridSize,
                                threadsPerThreadgroup: gridInfo.groupSize)
    }
    
    fileprivate static let bufferOffsetPostFix = "Offset"
    fileprivate static let threadgroupMemoryLengthPostFix = "MemoryLength"
}
