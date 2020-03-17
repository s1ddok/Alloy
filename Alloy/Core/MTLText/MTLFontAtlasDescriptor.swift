#if os(iOS)

import Metal
import UIKit.UIFont

public final class MTLFontAtlasDescriptor: Hashable {

    let fontName: String
    let textureSize: Int

    public init(fontName: String,
                textureSize: Int) {
        self.fontName = fontName
        self.textureSize = textureSize
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.fontName)
        hasher.combine(self.textureSize)
    }

    public static func == (lhs: MTLFontAtlasDescriptor,
                           rhs: MTLFontAtlasDescriptor) -> Bool {
        return lhs.fontName == rhs.fontName
            && lhs.textureSize == rhs.textureSize
    }
}

#endif
