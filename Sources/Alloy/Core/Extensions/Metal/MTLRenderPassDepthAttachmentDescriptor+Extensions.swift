import Metal

public extension MTLRenderPassDepthAttachmentDescriptor {
    /// slightly more useful type for MTLLoadAction
    enum LoadAction {
        case dontCare
        case load
        case clear(Double)
    }

    func setLoadAction(_ action: LoadAction) {
        switch action {
        case .dontCare:
            self.loadAction = .dontCare
        case .load:
            self.loadAction = .load
        case .clear(let value):
            self.loadAction = .clear
            self.clearDepth = value
        }
    }
}
