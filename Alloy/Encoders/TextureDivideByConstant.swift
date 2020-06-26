import Metal

final public class TextureDivideByConstant {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Init

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        try self.init(library: context.library(for: Bundle.module),
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        let functionName = Self.functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(sourceTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               constant: SIMD4<Float>,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    constant: constant,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               constant: SIMD4<Float>,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    constant: constant,
                    using: encoder)
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       constant: SIMD4<Float>,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Divide by Constant"
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        constant: constant,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       constant: SIMD4<Float>,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture,
                               destinationTexture])
        encoder.set(constant, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: sourceTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: sourceTexture.size)
        }
    }
    
    public func callAsFunction(sourceTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               constant: MTLBuffer,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    constant: constant,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               constant: MTLBuffer,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    constant: constant,
                    using: encoder)
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       constant: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Divide by Constant"
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        constant: constant,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       constant: MTLBuffer,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture,
                               destinationTexture])
        encoder.setBuffer(constant, offset: 0, index: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: sourceTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: sourceTexture.size)
        }
    }

    public static let functionName = "divideByConstant"
}

