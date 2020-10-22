import Foundation
import ImageIO

extension CGImage {
    
    enum Error: Swift.Error {
        case cgImageCreationFailed
    }
    
    static func initFromURL(_ url: URL) throws -> CGImage {
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else { throw Error.cgImageCreationFailed }
        return cgImage
    }
    
}
