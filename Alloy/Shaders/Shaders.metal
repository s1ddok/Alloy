//
//  Shaders.metal
//  AIBeauty
//
//  Created by Andrey Volodin on 08.08.2018.
//  Copyright © 2018 Andrey Volodin. All rights reserved.
//

#include <metal_stdlib>
#include "ColorConversion.h"

using namespace metal;

constant bool deviceSupportsFeaturesOfGPUFamily4_v1 [[function_constant(0)]];

kernel void textureCopy(texture2d<half, access::read> texture1 [[ texture(0) ]],
                        texture2d<half, access::write> texture2 [[ texture(1) ]],
                        const ushort2 position [[thread_position_in_grid]]) {
    if (!deviceSupportsFeaturesOfGPUFamily4_v1) {
        if (position.x >= texture1.get_width() || position.y >= texture1.get_height()) {
            return;
        }
    }

    const half4 c1 = texture1.read(position);

    texture2.write(c1, position);
}
