//
//  ONNXConvolutionPadding.swift
//  Alloy
//
//  Created by Andrey Volodin on 16/04/2019.
//

import MetalPerformanceShaders

public typealias Kernel = (height: Int, width: Int)
public typealias Strides = (height: Int, width: Int)
public typealias Dilations = (height: Int, width: Int)
public typealias Pads = (top: Int, left: Int, bottom: Int, right: Int)
public typealias Padding = (height: Int, width: Int)
public typealias Scales = (height: Int, width: Int)

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
@objc(ONNXConvolutionPadding) public class ONNXConvolutionPadding: NSObject, MPSNNPadding {
    public let kernel: Kernel
    public let dilations: Dilations
    public let strides: Strides
    public let pads: Pads
    public let outputPadding: Padding
    public let isTranspose: Bool

    public init(kernel: Kernel,
                strides: Strides,
                dilations: Dilations,
                pads: Pads,
                outputPadding: Padding,
                isTranspose: Bool) {
        self.kernel = kernel
        self.dilations = dilations
        self.strides = strides
        self.pads = pads
        self.outputPadding = outputPadding
        self.isTranspose = isTranspose
    }

    required convenience public init?(coder aDecoder: NSCoder) {
        guard
            let data = aDecoder.decodeData(),
            let other = NSKeyedUnarchiver.unarchiveObject(with: data) as? ONNXConvolutionPadding
        else { return nil }
        self.init(kernel: other.kernel,
                  strides: other.strides,
                  dilations: other.dilations,
                  pads: other.pads,
                  outputPadding: other.outputPadding,
                  isTranspose: other.isTranspose)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: self))
    }

    public func paddingMethod() -> MPSNNPaddingMethod {
        return [.custom]
    }

    public func destinationImageDescriptor(forSourceImages sourceImages: [MPSImage],
                                           sourceStates: [MPSState]?,
                                           for kernel: MPSKernel,
                                           suggestedDescriptor inDescriptor: MPSImageDescriptor) -> MPSImageDescriptor {
        let inputHeight = sourceImages[0].height
        let inputWidth = sourceImages[0].width

        if self.isTranspose {
            inDescriptor.height = (inputHeight - 1) * self.strides.height
                                - self.pads.top - self.pads.bottom
                                + self.kernel.height + self.outputPadding.height
            inDescriptor.width = (inputWidth - 1) * self.strides.width
                               - self.pads.left - self.pads.right
                               + self.kernel.width + self.outputPadding.width
            let conv = kernel as! MPSCNNConvolutionTranspose
            conv.offset = MPSOffset(x: 0, y: 0, z: 0)
            conv.edgeMode = .zero
            conv.kernelOffsetX = self.kernel.width / 2 - self.kernel.width + 1 + self.pads.left
            conv.kernelOffsetY = self.kernel.height / 2 - self.kernel.height + 1 + self.pads.top
        } else {
            inDescriptor.height = (inputHeight + self.pads.top + self.pads.bottom - self.kernel.height) / self.strides.height + 1
            inDescriptor.width = (inputWidth + self.pads.left + self.pads.right - self.kernel.width) / self.strides.width + 1
            let conv = kernel as! MPSCNNConvolution
            conv.offset = MPSOffset(x: self.kernel.width / 2 - self.pads.left,
                                    y: self.kernel.height / 2 - self.pads.top,
                                    z: 0)
            conv.edgeMode = .zero
        }

        return inDescriptor
    }

    public static var supportsSecureCoding: Bool = true
}
