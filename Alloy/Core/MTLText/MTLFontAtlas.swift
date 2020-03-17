#if os(iOS)

import Metal
import UIKit.UIFont

final public class MTLFontAtlas {
    let font: UIFont
    let glyphDescriptors: [GlyphDescriptor]
    let fontAtlasTexture: MTLTexture

    public init(font: UIFont,
                glyphDescriptors: [GlyphDescriptor],
                fontAtlasTexture: MTLTexture) {
        self.font = font
        self.glyphDescriptors = glyphDescriptors
        self.fontAtlasTexture = fontAtlasTexture
    }

    public func codable() throws -> MTLFontAtlasCodableBox {
        return try .init(fontAtlas: self)
    }
}

final public class MTLFontAtlasCodableBox: Codable {
    private let fontName: String
    private let fontSize: CGFloat
    private let glyphDescriptors: [GlyphDescriptor]
    private let fontAtlasTextureCodableBox: MTLTextureCodableBox

    public init(fontAtlas: MTLFontAtlas) throws {
        self.fontName = fontAtlas.font.fontName
        self.fontSize = fontAtlas.font.pointSize
        self.glyphDescriptors = fontAtlas.glyphDescriptors
        self.fontAtlasTextureCodableBox = try fontAtlas.fontAtlasTexture.codable()
    }

    public func fontAtlas(device: MTLDevice) throws -> MTLFontAtlas {
        return try .init(font: UIFont(name: self.fontName,
                                      size: self.fontSize)!,
                         glyphDescriptors: self.glyphDescriptors,
                         fontAtlasTexture: self.fontAtlasTextureCodableBox
                                               .texture(device: device))
    }
}

#endif
