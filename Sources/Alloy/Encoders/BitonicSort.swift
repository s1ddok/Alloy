import Foundation
import Metal
import simd

final public class BitonicSort<T: MetalCompatibleScalar> {

    // MARK: - Properties

    private let bitonicSort: MTLComputePipelineState
    private let bitonicSortFirstRun: MTLComputePipelineState
    private let bitonicSortInThreadGroup: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    private var mtlParameter: MTLBuffer
    private var dataBuffer: MTLBuffer!
    private var count = 0
    private var paddedCount = 0

    var use_threadgroup = true

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: .module))
    }

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)

        let `extension` = "_" + T.scalarType.rawValue
        self.bitonicSort = try library.computePipelineState(function: "bitonicSort" + `extension`)
        self.bitonicSortFirstRun = try library.computePipelineState(function: "bitonicSortFirstRun" + `extension`)
        self.bitonicSortInThreadGroup = try library.computePipelineState(function: "bitonicSortInThreadGroup" + `extension`)

        // make parameter table for first run
        let target = self.bitonicSortFirstRun.maxTotalThreadsPerThreadgroup
        var v = simd_uint2(repeating: 1)
        var params: [simd_uint2] = []
        while v.x <= target {
            v.y = v.x
            v.x <<= 1
            while v.y > .zero {
                params.append(v)
                v.y >>= 1
            }
        }

        self.mtlParameter = try library.device.buffer(with: params,
                                                      options: .storageModeShared)
    }

    public func setData(_ array: [T]) throws {
        self.count = array.count
        self.paddedCount = 1 << UInt(ceil(log2f(.init(array.count))))

        self.dataBuffer = try self.bitonicSort.device.buffer(for: T.self,
                                                             count: self.paddedCount,
                                                             options: .storageModeShared)

        let bufferContents = self.dataBuffer.contents()
        bufferContents.initializeMemory(as: T.self,
                                        from: array,
                                        count: array.count)
        if array.count < self.paddedCount {
            bufferContents.advanced(by: MemoryLayout<T>.stride * array.count)
                          .initializeMemory(as: T.self,
                                            repeating: T.maximum as! T,
                                            count: self.paddedCount - array.count)
        }
    }

    public func getPointer() -> (UnsafePointer<T>, Int)? {
        guard let raw = self.dataBuffer?.contents()
        else { return nil }
        let p = UnsafePointer(raw.assumingMemoryBound(to: T.self))
        return (p, self.count)
    }

    public func encode(in commandBuffer: MTLCommandBuffer) {
        let gridSize = MTLSize(width: self.paddedCount >> 1,
                               height: 1,
                               depth: 1)
        let unitSize = min(gridSize.width,
                           self.bitonicSort.maxTotalThreadsPerThreadgroup)
        let threadGroupSize = MTLSize(width: unitSize,
                                      height: 1,
                                      depth: 1)
        var params = SIMD2<UInt32>(repeating: 1)

        // first run
        commandBuffer.compute { encoder in
            params.x = UInt32(unitSize << 1)
            encoder.label = "Bitonic Sort First Run, params: \(params)"
            encoder.setComputePipelineState(self.bitonicSortFirstRun)
            encoder.setBuffer(self.mtlParameter, offset: 0, index: 0)
            encoder.setBuffer(self.dataBuffer, offset: 0, index: 1)
            encoder.setThreadgroupMemoryLength((MemoryLayout<T>.stride * unitSize) << 1,
                                               index: 0)
            encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        }

        while params.x < self.paddedCount {
            params.y = params.x
            params.x <<= 1
            repeat {
                if unitSize < params.y {
                    commandBuffer.compute { encoder in
                        encoder.label = "Bitonic Sort, params: \(params)"
                        encoder.setComputePipelineState(self.bitonicSort)
                        encoder.setValue(params, at: 0)
                        encoder.setBuffers(self.dataBuffer, startingAt: 1)
                        params.y >>= 1
                        encoder.dispatchThreads(gridSize,
                                                threadsPerThreadgroup: threadGroupSize)
                    }
                }
                else {
                    commandBuffer.compute { encoder in
                        encoder.label = "Bitonic Sort In Threadgroup, params: \(params)"
                        encoder.setComputePipelineState(self.bitonicSortInThreadGroup)
                        encoder.setValue(params, at: 0)
                        encoder.setBuffers(self.dataBuffer, startingAt: 1)
                        encoder.setThreadgroupMemoryLength((MemoryLayout<T>.stride * unitSize) << 1,
                                                           index: 0)
                        params.y = .zero
                        encoder.dispatchThreads(gridSize,
                                                threadsPerThreadgroup: threadGroupSize)
                    }
                }
            } while params.y > .zero
        }
    }

}
