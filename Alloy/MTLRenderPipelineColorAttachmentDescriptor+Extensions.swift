//
//  MTLRenderPipelineColorAttachmentDescriptor+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 26/04/2019.
//

import Metal

public extension MTLRenderPipelineColorAttachmentDescriptor {

    enum BlendingType {
        case none, add
    }

    func setup(blending: BlendingType) {
        switch blending {
        case .none:
            self.isBlendingEnabled = false
        case .add:
            self.isBlendingEnabled = true

            self.rgbBlendOperation = .add
            self.sourceRGBBlendFactor = .sourceAlpha
            self.destinationRGBBlendFactor = .oneMinusSourceAlpha

            self.alphaBlendOperation = .add
            self.sourceAlphaBlendFactor = .sourceAlpha
            self.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }
    }

}
