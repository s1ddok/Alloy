//
//  NSImage+Extenions.swift
//  Demo
//
//  Created by Eugene Bokhan on 04.12.2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

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
