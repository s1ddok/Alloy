import XCTest
import Alloy

@available(iOS 11, macOS 10.15, *)
class PerformanceTests: XCTestCase {

    var context: MTLContext!

    var evenInitState: MTLComputePipelineState!
    var evenOptimizedInitState: MTLComputePipelineState!
    var exactInitState: MTLComputePipelineState!

    var evenProcessState: MTLComputePipelineState!
    var evenOptimizedProcessState: MTLComputePipelineState!
    var exactProcessState: MTLComputePipelineState!

    let textureBaseWidth = 1024
    let textureBaseHeight = 1024
    let gpuIterations = 4

    override func setUpWithError() throws {
        self.context = try MTLContext()

        let library = try self.context.library(for: .module)

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

            try self.attach(totalGPUTime / CFTimeInterval(iterations),
                            name: "\(#function) average GPU Time")
        }

        catch { fatalError(error.localizedDescription) }
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

