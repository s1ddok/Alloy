import Metal

final public class TextureMax {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        try self.init(library: context.library(for: Self.self),
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        let functionName = Self.functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName)
    }

    // MARK: - Encode

    public func callAsFunction(source: MTLTexture,
                               result: MTLBuffer,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    result: result,
                    in: commandBuffer)
    }
    
    public func callAsFunction(source: MTLTexture,
                               result: MTLBuffer,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(source: source,
                    result: result,
                    using: encoder)
    }
    
    public func encode(source: MTLTexture,
                       result: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Max"
            self.encode(source: source,
                        result: result,
                        using: encoder)
        }
    }

    public func encode(source: MTLTexture,
                       result: MTLBuffer,
                       using encoder: MTLComputeCommandEncoder) {
        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1).clamped(to: source.size)
        let blockSizeWidth = (source.width + threadgroupSize.width - 1)
                           / threadgroupSize.width
        let blockSizeHeight = (source.height + threadgroupSize.height - 1)
                            / threadgroupSize.height
        let blockSize = BlockSize(width: blockSizeWidth,
                                  height: blockSizeHeight)

        encoder.set(textures: [source])
        encoder.set(blockSize, at: 0)
        encoder.setBuffer(result,
                          offset: 0,
                          index: 1)

        let threadgroupMemoryLength = threadgroupSize.width
                                    * threadgroupSize.height
                                    * 4
                                    * MemoryLayout<Float16>.stride

        encoder.setThreadgroupMemoryLength(threadgroupMemoryLength,
                                           index: 0)
        encoder.dispatch2d(state: self.pipelineState,
                           covering: .one,
                           threadgroupSize: threadgroupSize)
    }

    public static let functionName = "textureMax"
}
