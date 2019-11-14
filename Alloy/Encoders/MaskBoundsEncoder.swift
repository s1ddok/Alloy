//
//  MaskBoundsEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14.11.2019.
//

import Metal

final public class MaskBoundsEncoder {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let atomicMinXBuffer: MTLBuffer
    private let atomicMinYBuffer: MTLBuffer
    private let atomicMaxXBuffer: MTLBuffer
    private let atomicMaxYBuffer: MTLBuffer

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let library = context.shaderLibrary(for: type(of: self))
        else { throw CommonErrors.metalInitializationFailed }
        try self.init(library: library)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        let functionName = type(of: self).functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName)

        var minXInitialValue = UInt32.max
        var minYInitialValue = UInt32.max
        var maxXInitialValue = UInt32.min
        var maxYInitialValue = UInt32.min

        guard let atomicMinXBuffer = library.device
                                            .makeBuffer(bytes: &minXInitialValue,
                                                        length: MemoryLayout<UInt32>.stride,
                                                        options: .storageModeShared),
              let atomicMinYBuffer = library.device
                                            .makeBuffer(bytes: &minYInitialValue,
                                                        length: MemoryLayout<UInt32>.stride,
                                                        options: .storageModeShared),
              let atomicMaxXBuffer = library.device
                                            .makeBuffer(bytes: &maxXInitialValue,
                                                        length: MemoryLayout<UInt32>.stride,
                                                        options: .storageModeShared),
              let atomicMaxYBuffer = library.device
                                            .makeBuffer(bytes: &maxYInitialValue,
                                                        length: MemoryLayout<UInt32>.stride,
                                                        options: .storageModeShared)
        else { throw CommonErrors.metalInitializationFailed }

        self.atomicMinXBuffer = atomicMinXBuffer
        self.atomicMinYBuffer = atomicMinYBuffer
        self.atomicMaxXBuffer = atomicMaxXBuffer
        self.atomicMaxYBuffer = atomicMaxYBuffer
    }

    // MARK: - Encode

    /// Encode the kernel and get the result as uint4 value describing origin and size of mask bounds.
    /// - Parameters:
    ///   - sourceTexture: Mask source texture.
    ///   - resultBuffer: Result uint4 buffer.
    ///   - commandBuffer: Command buffer.
    public func encode(sourceTexture: MTLTexture,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Mask Bounds"
            self.encode(sourceTexture: sourceTexture,
                        resultBuffer: resultBuffer,
                        using: encoder)
        }
    }

    /// Encode the kernel and get the result as uint4 value describing origin and size of mask bounds.
    /// - Parameters:
    ///   - sourceTexture: Mask source texture.
    ///   - resultBuffer: Result uint4 buffer.
    ///   - encoder: Compute command encode.
    public func encode(sourceTexture: MTLTexture,
                       resultBuffer: MTLBuffer,
                       using encoder: MTLComputeCommandEncoder) {
        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1).clamped(to: sourceTexture.size)
        let width = UInt16((sourceTexture.width + threadgroupSize.width - 1) / threadgroupSize.width)
        let height = UInt16((sourceTexture.height + threadgroupSize.height - 1) / threadgroupSize.height)
        let blockSize = BlockSize(width: width, height: height)

        encoder.set(textures: [sourceTexture])
        encoder.set(blockSize, at: 0)
        encoder.setBuffer(self.atomicMinXBuffer,
                          offset: 0,
                          index: 1)
        encoder.setBuffer(self.atomicMinYBuffer,
                          offset: 0,
                          index: 2)
        encoder.setBuffer(self.atomicMaxXBuffer,
                          offset: 0,
                          index: 3)
        encoder.setBuffer(self.atomicMaxYBuffer,
                          offset: 0,
                          index: 4)
        encoder.setBuffer(resultBuffer,
                          offset: 0,
                          index: 5)

        encoder.dispatch2d(state: self.pipelineState,
                           covering: .one,
                           threadgroupSize: threadgroupSize)
    }

    public static let functionName = "maskBounds"
}
