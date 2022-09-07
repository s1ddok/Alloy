import Metal

public extension MTLRenderPassColorAttachmentDescriptor {
    /// slightly more useful type for MTLLoadAction
    enum LoadAction {
        case dontCare
        case load
        case clear(MTLClearColor)
    }

    func setLoadAction(_ action: LoadAction) {
        switch action {
        case .dontCare:
            self.loadAction = .dontCare
        case .load:
            self.loadAction = .load
        case .clear(let color):
            self.loadAction = .clear
            self.clearColor = color
        }
    }
}
