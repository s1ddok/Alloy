#if os(macOS)
import Cocoa

extension NSImage {
    var cgImage: CGImage? {
        guard let imageData = self.tiffRepresentation,
              let sourceData = CGImageSourceCreateWithData(imageData as CFData,
                                                           nil)
        else { return nil }
        return CGImageSourceCreateImageAtIndex(sourceData, 0, nil)
    }
}
#endif
