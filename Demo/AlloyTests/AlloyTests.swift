import XCTest
import Alloy
import MetalKit

@available(iOS 11, macOS 10.15, *)
class AlloyTests: XCTestCase {

    var context: MTLContext! = nil

    var evenInitState: MTLComputePipelineState! = nil
    var evenOptimizedInitState: MTLComputePipelineState! = nil
    var exactInitState: MTLComputePipelineState! = nil

    var evenProcessState: MTLComputePipelineState! = nil
    var evenOptimizedProcessState: MTLComputePipelineState! = nil
    var exactProcessState: MTLComputePipelineState! = nil

    var textureBaseWidth = 1024
    var textureBaseHeight = 1024
    var gpuIterations = 4

    override func setUp() {
        do {
            self.context = try MTLContext()

            let library = try self.context.library(for: Self.self)

            self.evenInitState = try library.computePipelineState(function: "initialize_even")

            let computeStateDescriptor = MTLComputePipelineDescriptor()
            computeStateDescriptor.computeFunction = library.makeFunction(name: "initialize_even")!
            computeStateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

            self.evenOptimizedInitState = try self.context
                                                  .computePipelineState(descriptor: computeStateDescriptor,
                                                                        options: [],
                                                                        reflection: nil)

            self.exactInitState = try library.computePipelineState(function: "initialize_exact")

            self.evenProcessState = try library.computePipelineState(function: "process_even")

            let processComputeStateDescriptor = MTLComputePipelineDescriptor()
            processComputeStateDescriptor.computeFunction = library.makeFunction(name: "process_even")!
            processComputeStateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

            self.evenOptimizedProcessState = try self.context
                                                     .computePipelineState(descriptor: processComputeStateDescriptor,
                                                                           options: [],
                                                                           reflection: nil)

            self.exactProcessState = try library.computePipelineState(function: "process_exact")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEvenPerformance() {
        self.measure {
            self.runGPUWork { (encoder, texture, output) in
                encoder.setTexture(texture, index: 0)
                encoder.dispatch2d(state: self.evenInitState, covering: texture.size)

                encoder.setTexture(output, index: 1)
                encoder.dispatch2d(state: self.evenProcessState, covering: texture.size)
            }
        }
    }

    func testEvenOptimizedPerformance() {
        self.measure {
            self.runGPUWork { (encoder, texture, output) in
                encoder.setTexture(texture, index: 0)
                encoder.dispatch2d(state: self.evenOptimizedInitState, covering: texture.size)

                encoder.setTexture(output, index: 1)
                encoder.dispatch2d(state: self.evenOptimizedProcessState, covering: texture.size)
            }
        }
    }

    func testExactPerformance() {
        self.measure {
            self.runGPUWork { (encoder, texture, output) in
                encoder.setTexture(texture, index: 0)
                encoder.dispatch2d(state: self.exactInitState, exactly: texture.size)

                encoder.setTexture(output, index: 1)
                encoder.dispatch2d(state: self.exactProcessState, exactly: texture.size)
            }
        }
    }

    func runGPUWork(encoding: (MTLComputeCommandEncoder, MTLTexture, MTLTexture) -> Void) {
        do {
            let maximumThreadgroupSize = evenInitState.max2dThreadgroupSize

            var totalGPUTime: CFTimeInterval = 0
            var iterations = 0

            for wd in 0..<maximumThreadgroupSize.width {
                for ht in 0..<maximumThreadgroupSize.height {
                    var texture = try self.context.texture(width:  self.textureBaseWidth + wd,
                                                           height: self.textureBaseHeight + ht,
                                                           pixelFormat: .rgba8Unorm)

                    var output = try self.context.texture(width:  self.textureBaseWidth + wd,
                                                          height: self.textureBaseHeight + ht,
                                                          pixelFormat: .rgba8Unorm)

                    try self.context.scheduleAndWait { buffer in
                        buffer.compute { encoder in
                            for _ in 0...self.gpuIterations {
                                encoding(encoder, texture, output)

                                swap(&texture, &output)
                            }
                        }

                        buffer.addCompletedHandler { buffer in
                            iterations += 1
                            totalGPUTime += buffer.gpuExecutionTime
                        }
                    }
                }

            }

            print("\(#function) average GPU Time: \(totalGPUTime / CFTimeInterval(iterations))")
        }

        catch { fatalError(error.localizedDescription) }
    }
}

@available(iOS 11, macOS 10.15, *)
class IdealSizeTests: XCTestCase {
    var context: MTLContext!

    var evenState: MTLComputePipelineState! = nil
    var evenOptimizedState: MTLComputePipelineState! = nil
    var exactState: MTLComputePipelineState! = nil

    var textureBaseMultiplier = 16
    var gpuIterations = 256

    override func setUp() {
        do {
            self.context = try MTLContext()

            let library = try self.context.library(for: .module)

            self.evenState = try library.computePipelineState(function: "fill_with_threadgroup_size_even")

            let computeStateDescriptor = MTLComputePipelineDescriptor()
            computeStateDescriptor.computeFunction = library.makeFunction(name: "fill_with_threadgroup_size_even")!
            computeStateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

            self.evenOptimizedState = try! self.context
                .device
                .makeComputePipelineState(descriptor: computeStateDescriptor,
                                          options: [],
                                          reflection: nil)

            self.exactState = try library.computePipelineState(function: "fill_with_threadgroup_size_exact")
        } catch { fatalError(error.localizedDescription) }
    }

    func testSpeedOnIdealSize() {
        do {
            var bestTimeCounter: [String: Int] = [:]

            for _ in 1...self.gpuIterations {
                let size = self.evenState.max2dThreadgroupSize
                let texture = try self.context
                                      .texture(width: size.width * self.textureBaseMultiplier,
                                               height: size.height * self.textureBaseMultiplier,
                                               pixelFormat: .rg16Uint,
                                               usage: .shaderWrite)

                var results = [(String, CFTimeInterval)]()

                try self.context.scheduleAndWait { buffer in
                    buffer.compute { encoder in
                        encoder.setTexture(texture, index: 0)
                        encoder.dispatch2d(state: self.evenState, covering: texture.size)
                    }

                    buffer.addCompletedHandler({ buffer in
                        results.append(("Even", buffer.gpuExecutionTime))
                    })
                }

                try self.context.scheduleAndWait { buffer in
                    buffer.compute { encoder in
                        encoder.setTexture(texture, index: 0)
                        encoder.dispatch2d(state: self.evenOptimizedState, covering: texture.size)
                    }

                    buffer.addCompletedHandler({ buffer in
                        results.append(("Even optimized", buffer.gpuExecutionTime))
                    })
                }

                try self.context.scheduleAndWait { buffer in
                    buffer.compute { encoder in
                        encoder.setTexture(texture, index: 0)
                        encoder.dispatch2d(state: self.exactState, exactly: texture.size)
                    }

                    buffer.addCompletedHandler({ buffer in
                        results.append(("Exact", buffer.gpuExecutionTime))
                    })
                }

                results.sort { $0.1 < $1.1 }
                bestTimeCounter[results.first!.0, default: 0] += 1
            }

            print(bestTimeCounter)
        }

        catch { fatalError(error.localizedDescription) }
    }

}
