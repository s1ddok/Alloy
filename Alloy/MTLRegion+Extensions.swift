//
//  MTLRegion+Extensions.swift
//  AIBeauty
//
//  Created by Andrey Volodin on 03.10.2018.
//

import Metal

public extension MTLRegion {
    public var minX: Int {
        return self.origin.x
    }
    
    public var minY: Int {
        return self.origin.y
    }
    
    public var minZ: Int {
        return self.origin.z
    }
    
    public var maxX: Int {
        return self.origin.x + self.size.width
    }
    
    public var maxY: Int {
        return self.origin.y + self.size.height
    }
    
    public var maxZ: Int {
        return self.origin.z + self.size.depth
    }
    
    public func clamped(to region: MTLRegion) -> MTLRegion? {
        let ox = max(self.origin.x, region.origin.x)
        let oy = max(self.origin.y, region.origin.y)
        let oz = max(self.origin.z, region.origin.z)
        
        let maxX = min(self.maxX, region.maxX)
        let maxY = min(self.maxY, region.maxY)
        let maxZ = min(self.maxZ, region.maxZ)
        
        guard ox < maxX && oy < maxY && oz < maxZ
        else { return nil }
        
        return MTLRegion(origin: MTLOrigin(x: ox,
                                           y: oy,
                                           z: oz),
                         size: MTLSize(width:  maxX - ox,
                                       height: maxY - oy,
                                       depth:  maxZ - oz))
        
    }
}
