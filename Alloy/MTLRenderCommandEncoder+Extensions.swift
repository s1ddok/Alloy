//
//  MTLRenderCommandEncoder+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 27/12/2018.
//

import Metal

public extension MTLRenderCommandEncoder {
    
    public func set<T>(vertexValue value: T, at index: Int) {
        var t = value
        self.setVertexBytes(&t, length: MemoryLayout<T>.stride, index: index)
    }
    
    public func set<T>(vertexValue value: T, at index: Int) where T: Collection {
        var t = value
        self.setVertexBytes(&t, length: MemoryLayout<T>.stride * value.count, index: index)
    }
    
    public func set<T>(fragmentValue value: T, at index: Int) {
        var t = value
        self.setFragmentBytes(&t, length: MemoryLayout<T>.stride, index: index)
    }
    
    public func set<T>(fragmentValue value: T, at index: Int) where T: Collection {
        var t = value
        self.setFragmentBytes(&t, length: MemoryLayout<T>.stride * value.count, index: index)
    }
    
    public func set(vertexTextures textures: [MTLTexture?], startingAt startIndex: Int = 0) {
        self.setVertexTextures(textures, range: startIndex..<(startIndex + textures.count))
    }
    
    public func set(fragmentTextures textures: [MTLTexture?], startingAt startIndex: Int = 0) {
        self.setFragmentTextures(textures, range: startIndex..<(startIndex + textures.count))
    }
    
    public func set(vertexBuffers buffers: [MTLBuffer?], offsets: [Int]? = nil, startingAt startIndex: Int = 0) {
        self.setVertexBuffers(buffers,
                              offsets: offsets ?? buffers.map { _ in 0 },
                              range: startIndex..<(startIndex + buffers.count))
    }
    
    public func set(fragmentBuffers buffers: [MTLBuffer?], offsets: [Int]? = nil, startingAt startIndex: Int = 0) {
        self.setFragmentBuffers(buffers,
                                offsets: offsets ?? buffers.map { _ in 0 },
                                range: startIndex..<(startIndex + buffers.count))
    }

}
