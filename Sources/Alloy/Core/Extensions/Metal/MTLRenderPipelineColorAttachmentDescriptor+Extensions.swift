import Metal

public typealias BlendingMode = MTLRenderPipelineColorAttachmentDescriptor.BlendingMode

public extension MTLRenderPipelineColorAttachmentDescriptor {

    /// Blend Mode Options
    enum BlendingMode {
        /// Disabled blending mode. Use this with fully opaque surfaces for extra performance.
        case none
        /// Regular alpha blending.
        case alpha
        /// Front to back rendering using alpha blending
        case reverseAlpha
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
        self.isBlendingEnabled = true
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
            self.sourceRGBBlendFactor = .sourceAlpha
            self.destinationRGBBlendFactor = .oneMinusSourceAlpha
            self.sourceAlphaBlendFactor = .sourceAlpha
            self.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        case .reverseAlpha:
            self.sourceRGBBlendFactor = .oneMinusDestinationAlpha
            self.sourceAlphaBlendFactor = .oneMinusDestinationAlpha
            self.destinationRGBBlendFactor = .one
            self.destinationAlphaBlendFactor = .one
        case .premultipliedAlpha:
            self.sourceRGBBlendFactor = .one
            self.destinationRGBBlendFactor = .oneMinusSourceAlpha
            self.sourceAlphaBlendFactor = .one
            self.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        case .add:
            self.sourceRGBBlendFactor = .one
            self.destinationRGBBlendFactor = .one
            self.sourceAlphaBlendFactor = .one
            self.destinationAlphaBlendFactor = .one
        case .multiply:
            self.sourceRGBBlendFactor = .destinationColor
            self.destinationRGBBlendFactor = .zero
            self.sourceAlphaBlendFactor = .destinationColor
            self.destinationAlphaBlendFactor = .zero
        case .multiplicative:
            self.sourceRGBBlendFactor = .destinationColor
            self.destinationRGBBlendFactor = .oneMinusSourceAlpha
            self.sourceAlphaBlendFactor = .destinationColor
            self.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        case .addWithAlpha:
            self.sourceRGBBlendFactor = .sourceAlpha
            self.destinationRGBBlendFactor = .zero
            self.sourceAlphaBlendFactor = .sourceAlpha
            self.destinationAlphaBlendFactor = .zero
        case .screen:
            self.sourceRGBBlendFactor = .oneMinusDestinationColor
            self.destinationRGBBlendFactor = .one
            self.sourceAlphaBlendFactor = .oneMinusDestinationColor
            self.destinationAlphaBlendFactor = .one
        case .dodge:
            self.sourceRGBBlendFactor = .oneMinusSourceAlpha
            self.destinationRGBBlendFactor = .one
            self.sourceAlphaBlendFactor = .oneMinusSourceAlpha
            self.destinationAlphaBlendFactor = .one
        }
    }

}
