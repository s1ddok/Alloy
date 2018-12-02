//
//  MTLSizeAndAlign+Extensions.swift
//  AIBeauty
//
//  Created by Andrey Volodin on 24.09.2018.
//

import Metal.MTLHeap

// Returns a size of the 'inSize' aligned to 'align' as long as align is a power of 2
func alignUp(size: Int, align: Int) -> Int {
    #if DEBUG
    precondition(((align-1) & align) == 0, "Align must be a power of two")
    #endif
    
    let alignmentMask = align - 1
    
    return (size + alignmentMask) & ~alignmentMask
}

public extension MTLSizeAndAlign {
    public func combined(with sizeAndAlign: MTLSizeAndAlign) -> MTLSizeAndAlign {
        let requiredAlignment = max(self.align, sizeAndAlign.align)
        let selfAligned = alignUp(size: self.size, align: requiredAlignment)
        let otherAligned = alignUp(size: sizeAndAlign.size, align: requiredAlignment)
        
        return MTLSizeAndAlign(size: selfAligned + otherAligned, align: requiredAlignment)
    }
}

public extension Sequence where Element == MTLTextureDescriptor {
    public func heapSizeAndAlignCombined(on device: MTLDevice) -> MTLSizeAndAlign {
        return self.reduce(MTLSizeAndAlign(size: 0, align: 0)) {
            $0.combined(with: device.heapTextureSizeAndAlign(descriptor: $1))
        }
    }
}

public extension MTLSize {
    public func clamped(to size: MTLSize) -> MTLSize {
        return MTLSize(width:  min(max(self.width, 0), size.width),
                       height: min(max(self.height, 0), size.height),
                       depth:  min(max(self.depth, 0), size.depth))
    }
    
    public static let zero = MTLSize(width: 0, height: 0, depth: 0)
}
