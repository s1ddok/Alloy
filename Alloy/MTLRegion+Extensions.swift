import Metal

public extension MTLRegion {
    var minX: Int {
        return self.origin.x
    }
    
    var minY: Int {
        return self.origin.y
    }
    
    var minZ: Int {
        return self.origin.z
    }
    
    var maxX: Int {
        return self.origin.x + self.size.width
    }
    
    var maxY: Int {
        return self.origin.y + self.size.height
    }
    
    var maxZ: Int {
        return self.origin.z + self.size.depth
    }

    var area: Int {
        self.size.width * self.size.height
    }
    
    func clamped(to region: MTLRegion) -> MTLRegion? {
        let ox = max(self.origin.x, region.origin.x)
        let oy = max(self.origin.y, region.origin.y)
        let oz = max(self.origin.z, region.origin.z)
        
        let maxX = min(self.maxX, region.maxX)
        let maxY = min(self.maxY, region.maxY)
        let maxZ = min(self.maxZ, region.maxZ)
        
        guard ox < maxX && oy < maxY && oz < maxZ
        else { return nil }
        
        return MTLRegion(origin: .init(x: ox,
                                       y: oy,
                                       z: oz),
                         size: .init(width:  maxX - ox,
                                     height: maxY - oy,
                                     depth:  maxZ - oz))
        
    }

    static func ==(lhs: MTLRegion, rhs: MTLRegion) -> Bool {
        return lhs.origin == rhs.origin
            && lhs.size == rhs.size
    }
}
