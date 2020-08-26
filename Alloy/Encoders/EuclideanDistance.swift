import Metal

final public class EuclideanDistance {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState

    // MARK: - Life Cycle

    convenience public init(context: MTLContext,
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

    public func callAsFunction(textureOne: MTLTexture,
                               textureTwo: MTLTexture,
                               resultBuffer: MTLBuffer,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(textureOne: textureOne,
                    textureTwo: textureTwo,
                    resultBuffer: resultBuffer,
                    in: commandBuffer)
    }

    public func callAsFunction(textureOne: MTLTexture,
                               textureTwo: MTLTexture,
                               resultBuffer: MTLBuffer,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(textureOne: textureOne,
                    textureTwo: textureTwo,
                    resultBuffer: resultBuffer,
                    using: encoder)
    }

    public func encode(textureOne: MTLTexture,
                       textureTwo: MTLTexture,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Euclidean Distance"
            self.encode(textureOne: textureOne,
                            textureTwo: textureTwo,
                            resultBuffer: resultBuffer,
                            using: encoder)
        }
    }

    public func encode(textureOne: MTLTexture,
                       textureTwo: MTLTexture,
                       resultBuffer: MTLBuffer,
                       using encoder: MTLComputeCommandEncoder) {
        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1).clamped(to: textureOne.size)
        let blockSizeWidth = (textureOne.width + threadgroupSize.width - 1)
                           / threadgroupSize.width
        let blockSizeHeight = (textureOne.height + threadgroupSize.height - 1)
                            / threadgroupSize.height
        let blockSize = BlockSize(width: blockSizeWidth,
                                  height: blockSizeHeight)

        encoder.setTextures(textureOne, textureTwo)
        encoder.setValue(blockSize, at: 0)
        encoder.setBuffer(resultBuffer,
                          offset: 0,
                          index: 1)

        let threadgroupMemoryLength = threadgroupSize.width
                                    * threadgroupSize.height
                                    * MemoryLayout<Float>.stride

        encoder.setThreadgroupMemoryLength(threadgroupMemoryLength,
                                           index: 0)
        encoder.dispatch2d(state: self.pipelineState,
                           covering: .one,
                           threadgroupSize: threadgroupSize)
    }

    public static let functionName = "euclideanDistance"
}
