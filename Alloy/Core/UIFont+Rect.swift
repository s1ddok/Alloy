#if os(iOS)

import UIKit

extension UIFont {

    var estimatedLineWidth: CGFloat {
        let string: NSString = "!"
        let stringSize = string.size(withAttributes: [NSAttributedString.Key.font : self])
        return .init(ceilf(.init(stringSize.width)))
    }

    var estimatedGlyphSize: CGSize {
        let string: NSString = "{ǺOJMQYZa@jmqyw"
        let stringSize = string.size(withAttributes: [NSAttributedString.Key.font : self])
        let averageGlyphWidth = CGFloat(ceilf(.init(stringSize.width) / .init(string.length)))
        let maxGlyphHeight = CGFloat(ceilf(.init(stringSize.height)))
        return .init(width: averageGlyphWidth,
                     height: maxGlyphHeight)
    }

    var ctFont: CTFont {
        CTFontCreateWithName(self.fontName as CFString,
                             self.pointSize,
                             nil)
    }

    private func fits(in rect: CGRect) -> Bool {
        let area = rect.size.width * rect.size.height
        let fontGlyphCount = CTFontGetGlyphCount(self.ctFont)
        let glyphMargin = self.estimatedLineWidth
        let averageGlyphSize = self.estimatedGlyphSize
        let estimatedGlyphTotalArea = (averageGlyphSize.width + glyphMargin)
                                    * (averageGlyphSize.height + glyphMargin)
                                    * .init(fontGlyphCount)
        return estimatedGlyphTotalArea < area
    }

    private func fontWithSizeFitsInRect(fontSize: CGFloat,
                                        rect: CGRect) -> Bool {
        let area = rect.size.width * rect.size.height
        let trialFont = UIFont(name: self.fontName, size: fontSize)!
        let trialCTFont = CTFontCreateWithName(self.fontName as CFString,
                                               fontSize,
                                               nil)
        let fontGlyphCount = CTFontGetGlyphCount(trialCTFont)
        let glyphMargin = trialFont.estimatedLineWidth
        let averageGlyphSize = trialFont.estimatedGlyphSize
        let estimatedGlyphTotalArea = (averageGlyphSize.width + glyphMargin)
                                    * (averageGlyphSize.height + glyphMargin)
                                    * .init(fontGlyphCount)
        return estimatedGlyphTotalArea < area
    }

    convenience init?(name fontName: String,
                      rect: CGRect,
                      trialFontSize: CGFloat = 32) {
        let fittedPointSize = Self.calculatedFontSizeToFit(rect: rect,
                                                           fontName: fontName,
                                                           trialFontSize: trialFontSize)
        self.init(name: fontName,
                  size: fittedPointSize)
    }

    private static func calculatedFontSizeToFit(rect: CGRect,
                                                fontName: String,
                                                trialFontSize: CGFloat) -> CGFloat {
        var fittedSize = trialFontSize
        while UIFont(name: fontName, size: fittedSize)?.fits(in: rect) ?? false {
            fittedSize += 1
        }

        while !(UIFont(name: fontName, size: fittedSize)?.fits(in: rect) ?? true) {
            fittedSize -= 1
        }
        return fittedSize
    }


}

#endif
