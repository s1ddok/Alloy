#if os(macOS)
import Foundation

public extension NSColor {
    var metalColor: MTLClearColor {
        return .init(red: self.redComponent,
                     green: self.greenComponent,
                     blue: self.blueComponent,
                     alpha: self.alphaComponent)
    }
}
#endif
