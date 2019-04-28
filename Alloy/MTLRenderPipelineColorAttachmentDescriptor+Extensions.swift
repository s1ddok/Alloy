//
//  MTLRenderPipelineColorAttachmentDescriptor+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 26/04/2019.
//

import Metal

public extension MTLRenderPipelineColorAttachmentDescriptor {

    /// Blend Mode Options
    enum BlendingMode {
        /// Disabled blending mode. Use this with fully opaque surfaces for extra performance.
        case none
        /// Regular alpha blending.
        case alpha
        /// Pre-multiplied alpha blending. (This is usually the default)
        case premultipliedAlpha
        /// Additive blending. (Similar to PhotoShop's linear dodge mode)
        case add
        /// Multiply blending mode. (Similar to PhotoShop's burn mode)
        case multiply
        /// A (better) multiply blending mode.
        case multiplicative
        /// A (better) add mode.
        case addWithAlpha
        /// Similar to PhotoShop's screen mode.
        case screen
        /// Similar to PhotoShop's dodge mode.
        case dodge
    }

    /// Setup a certain blending mode.
    ///
    /// - Parameter blending: Blending mode.
    func setup(blending: BlendingMode) {
        // Default
        self.rgbBlendOperation = .add
        self.sourceRGBBlendFactor = .one
        self.destinationRGBBlendFactor = .zero
        self.alphaBlendOperation = .add
        self.sourceAlphaBlendFactor = .one
        self.destinationAlphaBlendFactor = .zero

        switch blending {
        case .none:
            self.isBlendingEnabled = false
        case .alpha:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .sourceAlpha
            self.destinationRGBBlendFactor = .oneMinusSourceAlpha
        case .premultipliedAlpha:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .one
            self.destinationRGBBlendFactor = .oneMinusSourceAlpha
        case .add:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .one
            self.destinationRGBBlendFactor = .one
        case .multiply:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .destinationColor
            self.destinationRGBBlendFactor = .zero
        case .multiplicative:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .destinationColor
            self.destinationRGBBlendFactor = .oneMinusSourceAlpha
        case .addWithAlpha:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .sourceAlpha
            self.destinationRGBBlendFactor = .zero
        case .screen:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .oneMinusDestinationColor
            self.destinationRGBBlendFactor = .one
        case .dodge:
            self.isBlendingEnabled = true
            self.sourceRGBBlendFactor = .oneMinusSourceAlpha
            self.destinationRGBBlendFactor = .one
        }
    }

}
