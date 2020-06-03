import Metal

final public class TextureCopy {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        try self.init(library: context.library(for: Self.self),
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
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    using: encoder)
    }

    public func callAsFunction(region sourceTexureRegion: MTLRegion,
                               from sourceTexture: MTLTexture,
                               to destinationTextureOrigin: MTLOrigin,
                               of destinationTexture: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.copy(region: sourceTexureRegion,
                  from: sourceTexture,
                  to: destinationTextureOrigin,
                  of: destinationTexture,
                  in: commandBuffer)
    }

    public func callAsFunction(region sourceTexureRegion: MTLRegion,
                               from sourceTexture: MTLTexture,
                               to destinationTextureOrigin: MTLOrigin,
                               of destinationTexture: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.copy(region: sourceTexureRegion,
                  from: sourceTexture,
                  to: destinationTextureOrigin,
                  of: destinationTexture,
                  using: encoder)
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Copy"
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        self.copy(region: sourceTexture.region,
                  from: sourceTexture,
                  to: .zero,
                  of: destinationTexture,
                  using: encoder)
    }

    public func copy(region sourceTexureRegion: MTLRegion,
                     from sourceTexture: MTLTexture,
                     to destinationTextureOrigin: MTLOrigin,
                     of destinationTexture: MTLTexture,
                     in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Copy"
            self.copy(region: sourceTexureRegion,
                      from: sourceTexture,
                      to: destinationTextureOrigin,
                      of: destinationTexture,
                      using: encoder)
        }
    }

    public func copy(region sourceTexureRegion: MTLRegion,
                     from sourceTexture: MTLTexture,
                     to destinationTextureOrigin: MTLOrigin,
                     of destinationTexture: MTLTexture,
                     using encoder: MTLComputeCommandEncoder) {
        // 1. Calculate read origin correction.
        let readOriginCorrection = MTLOrigin(x: abs(min(0, sourceTexureRegion.origin.x)),
                                             y: abs(min(0, sourceTexureRegion.origin.y)),
                                             z: 0)

        // 2. Clamp read region to read texture.
        guard var readRegion = sourceTexureRegion.clamped(to: sourceTexture.region)
        else {
            #if DEBUG
            print("Read region is less or outside of source texture.")
            #endif
            return
        }

        // 3. Write origin correction.
        var writeOrigin = MTLOrigin(x: destinationTextureOrigin.x + readOriginCorrection.x,
                                    y: destinationTextureOrigin.y + readOriginCorrection.y,
                                    z: 0)

        // 4. Calculate destination origin correction.
        let writeOriginCorrection = MTLOrigin(x: abs(min(0, writeOrigin.x)),
                                              y: abs(min(0, writeOrigin.y)),
                                              z: 0)

        // 5. Clamp origin destination.
        readRegion.origin.x += writeOriginCorrection.x
        readRegion.origin.y += writeOriginCorrection.x
        readRegion.size.width -= writeOriginCorrection.x
        readRegion.size.height -= writeOriginCorrection.y

        // 6. Clamp destination origin by destination texture.
        writeOrigin.x = max(0, writeOrigin.x)
        writeOrigin.y = max(0, writeOrigin.y)

        // 7. Calculate grid size.
        let gridSize = MTLSize(width: min(readRegion.size.width,
                                          destinationTexture.width - writeOrigin.x),
                               height: min(readRegion.size.height,
                                           destinationTexture.height - writeOrigin.y),
                               depth: 1)

        guard gridSize.width > 0
           && gridSize.height > 0
        else {
            #if DEBUG
            print("Grid size is less or equal to zero.")
            #endif
            return
        }

        let readOffset = SIMD2<Int16>(x: .init(readRegion.origin.x),
                                      y: .init(readRegion.origin.y))
        let writeOffset = SIMD2<Int16>(x: .init(writeOrigin.x),
                                       y: .init(writeOrigin.y))

        encoder.set(textures: [sourceTexture,
                               destinationTexture])
        encoder.set(readOffset,
                    at: 0)
        encoder.set(writeOffset,
                    at: 1)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: gridSize)
        } else {
            encoder.set(SIMD2<UInt16>(x: .init(gridSize.width),
                                      y: .init(gridSize.height)),
                        at: 2)
            encoder.dispatch2d(state: self.pipelineState,
                               covering: gridSize)
        }
    }

    public static let functionName = "textureCopy"
}
