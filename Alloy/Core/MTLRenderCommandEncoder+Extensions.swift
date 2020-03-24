//
//  MTLRenderCommandEncoder+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 27/12/2018.
//

import Metal

public extension MTLRenderCommandEncoder {
    
    func set<T>(vertexValue value: T, at index: Int) {
        var t = value
        self.setVertexBytes(&t, length: MemoryLayout<T>.stride, index: index)
    }
    
    func set<T>(vertexValue value: T, at index: Int) where T: Collection {
        var t = value
        self.setVertexBytes(&t, length: MemoryLayout<T>.stride * value.count, index: index)
    }
    
    func set<T>(fragmentValue value: T, at index: Int) {
        var t = value
        self.setFragmentBytes(&t, length: MemoryLayout<T>.stride, index: index)
    }
    
    func set<T>(fragmentValue value: T, at index: Int) where T: Collection {
        var t = value
        self.setFragmentBytes(&t, length: MemoryLayout<T>.stride * value.count, index: index)
    }
    
    func set(vertexTextures textures: [MTLTexture?], startingAt startIndex: Int = 0) {
        self.setVertexTextures(textures, range: startIndex..<(startIndex + textures.count))
    }
    
    func set(fragmentTextures textures: [MTLTexture?], startingAt startIndex: Int = 0) {
        self.setFragmentTextures(textures, range: startIndex..<(startIndex + textures.count))
    }
    
    func set(vertexBuffers buffers: [MTLBuffer?], offsets: [Int]? = nil, startingAt startIndex: Int = 0) {
        self.setVertexBuffers(buffers,
                              offsets: offsets ?? buffers.map { _ in 0 },
                              range: startIndex..<(startIndex + buffers.count))
    }
    
    func set(fragmentBuffers buffers: [MTLBuffer?], offsets: [Int]? = nil, startingAt startIndex: Int = 0) {
        self.setFragmentBuffers(buffers,
                                offsets: offsets ?? buffers.map { _ in 0 },
                                range: startIndex..<(startIndex + buffers.count))
    }

    func drawIndexedPrimitives(type: MTLPrimitiveType,
                               indexBuffer: MTLIndexBuffer,
                               instanceCount: Int = 1) {
        self.drawIndexedPrimitives(type: type,
                                   indexCount: indexBuffer.count,
                                   indexType: indexBuffer.type,
                                   indexBuffer: indexBuffer.buffer,
                                   indexBufferOffset: 0,
                                   instanceCount: instanceCount)
    }

    func drawIndexedPrimitives(type: MTLPrimitiveType,
                               indexBuffer: MTLIndexBuffer,
                               offset: Int,
                               count: Int,
                               instanceCount: Int = 1) {
        #if DEBUG
        guard count + offset <= indexBuffer.count else {
            fatalError("Requested index count exceeds provided buffer's length")
        }
        #endif

        self.drawIndexedPrimitives(type: type,
                                   indexCount: count,
                                   indexType: indexBuffer.type,
                                   indexBuffer: indexBuffer.buffer,
                                   indexBufferOffset: offset,
                                   instanceCount: instanceCount)
    }

}
