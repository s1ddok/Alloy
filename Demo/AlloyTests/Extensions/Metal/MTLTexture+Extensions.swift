//
//  MTLTexture+Extensions.swift
//  AlloyTests
//
//  Created by Eugene Bokhan on 03/09/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

import Metal

extension MTLTexture {

    func getLevel(_ level: Int,
                  slices: Range<Int> = 0 ..< 1) -> MTLTexture? {
        return self.makeTextureView(pixelFormat: self.pixelFormat,
                                    textureType: self.textureType,
                                    levels: level ..< (level + 1),
                                    slices: slices)
    }

}
