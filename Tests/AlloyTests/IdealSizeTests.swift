import XCTest
import Alloy

@available(iOS 11, macOS 10.15, *)
class IdealSizeTests: XCTestCase {
    
    var context: MTLContext!
    var evenState: MTLComputePipelineState!
    var evenOptimizedState: MTLComputePipelineState!
    var exactState: MTLComputePipelineState!

    let textureBaseMultiplier = 16
    let gpuIterations = 256

    override func setUpWithError() throws {
        self.context = try .init()

        let library = try self.context.library(for: .module)
        self.evenState = try library.computePipelineState(function: "fill_with_threadgroup_size_even")
        self.exactState = try library.computePipelineState(function: "fill_with_threadgroup_size_exact")

        let computeStateDescriptor = MTLComputePipelineDescriptor()
        computeStateDescriptor.computeFunction = library.makeFunction(name: "fill_with_threadgroup_size_even")!
        computeStateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

        self.evenOptimizedState = try self.context.computePipelineState(descriptor: computeStateDescriptor,
                                                                        options: [],
                                                                        reflection: nil)
    }

    func testSpeedOnIdealSize() throws {
        var bestTimeCounter: [String: Int] = [:]

        for _ in 1...self.gpuIterations {
            let size = self.evenState.max2dThreadgroupSize
            let texture = try self.context.texture(width: size.width * self.textureBaseMultiplier,
                                                   height: size.height * self.textureBaseMultiplier,
                                                   pixelFormat: .rg16Uint,
                                                   usage: .shaderWrite)

            var results = [(String, CFTimeInterval)]()

            try self.context.scheduleAndWait { buffer in
                buffer.compute { encoder in
                    encoder.setTexture(texture, index: 0)
                    encoder.dispatch2d(state: self.evenState, covering: texture.size)
                }

                buffer.addCompletedHandler{ buffer in
                    results.append(("Even", buffer.gpuExecutionTime))
                }
            }

            try self.context.scheduleAndWait { buffer in
                buffer.compute { encoder in
                    encoder.setTexture(texture, index: 0)
                    encoder.dispatch2d(state: self.evenOptimizedState, covering: texture.size)
                }

                buffer.addCompletedHandler{ buffer in
                    results.append(("Even optimized", buffer.gpuExecutionTime))
                }
            }

            try self.context.scheduleAndWait { buffer in
                buffer.compute { encoder in
                    encoder.setTexture(texture, index: 0)
                    encoder.dispatch2d(state: self.exactState, exactly: texture.size)
                }

                buffer.addCompletedHandler { buffer in
                    results.append(("Exact", buffer.gpuExecutionTime))
                }
            }

            results.sort { $0.1 < $1.1 }
            bestTimeCounter[results.first!.0, default: 0] += 1
        }

        try self.attach(bestTimeCounter,
                        name: "Best Time")
    }
    
    func attach<T: Codable>(_ value: T,
                            name: String,
                            lifetime: XCTAttachment.Lifetime = .keepAlways) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let resultAttachment = try XCTAttachment(data: encoder.encode(value))
        resultAttachment.name = name
        resultAttachment.lifetime = lifetime
        self.add(resultAttachment)
    }

}
