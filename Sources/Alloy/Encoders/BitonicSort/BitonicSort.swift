import Metal

final public class BitonicSort<T: MetalCompatibleScalar> {

    // MARK: - Properties

    private let firstPass: FirstPass
    private let generalPass: GeneralPass
    private let finalPass: FinalPass

    private var dataBuffer: MTLBuffer?
    private var count = 0
    private var paddedCount = 0

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: .module))
    }

    public init(library: MTLLibrary) throws {
        let scalarType = T.scalarType
        self.firstPass = try .init(library: library,
                                   scalarType: scalarType)
        self.generalPass = try .init(library: library,
                                     scalarType: scalarType)
        self.finalPass = try .init(library: library,
                                   scalarType: scalarType)
    }

    public func setData(_ array: [T]) throws {
        self.count = array.count
        self.paddedCount = 1 << UInt(ceil(log2f(.init(array.count))))

        let storageMode: MTLResourceOptions
        #if targetEnvironment(macCatalyst) || os(macOS)
        storageMode = .storageModeManaged
        defer {
            if #available(macOS 10.11, macCatalyst 14.0, *) {
                self.dataBuffer?.didModifyRange(0 ..< MemoryLayout<T>.stride * self.paddedCount)
            }
        }
        #else
        storageMode = .storageModeShared
        #endif

        let data = try self.generalPass
                           .pipelineState
                           .device
                           .buffer(for: T.self,
                                   count: self.paddedCount,
                                   options: storageMode)
        self.dataBuffer = data

        let bufferContents = data.contents()
        bufferContents.initializeMemory(as: T.self,
                                        from: array,
                                        count: array.count)
        if array.count < self.paddedCount,
           let maxValue = T.maximum as? T {
            bufferContents.advanced(by: MemoryLayout<T>.stride * array.count)
                          .initializeMemory(as: T.self,
                                            repeating: maxValue,
                                            count: self.paddedCount - array.count)
        }
    }

    public func getData() -> [T]? {
        guard let data = self.dataBuffer
        else { return nil }
        return data.array(of: T.self,
                          count: self.count)
    }

    public func encode(in commandBuffer: MTLCommandBuffer) {
        guard let data = self.dataBuffer
        else { return }

        let gridSize = self.paddedCount >> 1
        let unitSize = min(gridSize,
                           self.generalPass
                               .pipelineState
                               .maxTotalThreadsPerThreadgroup)

        var params = SIMD2<UInt32>(repeating: 1)

        self.firstPass(data: data,
                       gridSize: gridSize,
                       unitSize: unitSize,
                       in: commandBuffer)
        params.x = .init(unitSize << 1)

        while params.x < self.paddedCount {
            params.y = params.x
            params.x <<= 1
            repeat {
                if unitSize < params.y {
                    self.generalPass(data: data,
                                     params: params,
                                     gridSize: gridSize,
                                     unitSize: unitSize,
                                     in: commandBuffer)
                    params.y >>= 1
                } else {
                    self.finalPass(data: data,
                                   params: params,
                                   gridSize: gridSize,
                                   unitSize: unitSize,
                                   in: commandBuffer)
                    params.y = .zero
                }
            } while params.y > .zero
        }

        #if targetEnvironment(macCatalyst) || os(macOS)
        commandBuffer.blit { encoder in
            encoder.synchronize(resource: data)
        }
        #endif
    }

}
