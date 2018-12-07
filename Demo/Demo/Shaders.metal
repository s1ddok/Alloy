//
//  Shaders.metal
//  Demo
//
//  Created by Andrey Volodin on 02/12/2018.
//  Copyright © 2018 avolodin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void brightness(texture2d<half, access::read_write> input [[ texture(0) ]],
                       constant float& coeff [[ buffer(0) ]],
                       const ushort2 position [[thread_position_in_grid]]) {
    if (position.x >= input.get_width() || position.y >= input.get_height()) {
        return;
    }
    
    half4 originalValue = input.read(position);
    originalValue *= coeff;
    
    input.write(originalValue, position);
}
