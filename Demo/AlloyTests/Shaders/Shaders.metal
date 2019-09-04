//
//  Shaders.metal
//  AlloyTests
//
//  Created by Andrey Volodin on 20/01/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

#include <metal_stdlib>
#include "../../../Alloy/Shaders/Definitions.h"

using namespace metal;

constant bool deviceSupportsNonuniformThreadgroups [[ function_constant(0) ]];
constant bool conversionTypeDenormalize [[ function_constant(1) ]];

inline void init_common(texture2d<half, access::write> input, ushort2 position) {
    const float2 positionf = (float2)position;
    const float2 size = float2(input.get_width(), input.get_height());

    const float2 normalizedPosition = positionf / size;

    input.write(half4((half2)normalizedPosition, 0, 1), position);
}

kernel void initialize_even(texture2d<half, access::write> input [[texture(0)]],
                            ushort2 position [[ thread_position_in_grid ]]) {
    if (position.x >= input.get_width() || position.y >= input.get_height()) {
        return;
    }

    init_common(input, position);
}

kernel void initialize_exact(texture2d<half, access::write> input [[texture(0)]],
                            ushort2 position [[ thread_position_in_grid ]]) {
    init_common(input, position);
}

inline void process_common(texture2d<half, access::read> input,
                           texture2d<half, access::write> output,
                           ushort2 position) {
    half4 color = input.read(position);
    color.xy = color.yx;
    color = half4(pow(color.xyz, 1.h / 2.2h), 1.h);
    output.write(color, position);
}

kernel void process_even(texture2d<half, access::read> input [[texture(0)]],
                         texture2d<half, access::write> output [[texture(1)]],
                         ushort2 position [[ thread_position_in_grid ]]) {
    if (position.x >= input.get_width() || position.y >= input.get_height()) {
        return;
    }

    process_common(input, output, position);
}

kernel void process_exact(texture2d<half, access::read> input [[texture(0)]],
                          texture2d<half, access::write> output [[texture(1)]],
                          ushort2 position [[ thread_position_in_grid ]]) {
    process_common(input, output, position);
}

kernel void fill_with_threadgroup_size_exact(texture2d<ushort, access::write> output [[ texture(0) ]],
                                             ushort2 position [[ thread_position_in_grid]],
                                             ushort2 threadgroupSize [[threads_per_threadgroup]]) {
    uint dummyVal = 0;
    for (int i = 0; i < 10000000; i++) {
        dummyVal += position.y;
    }

    output.write(ushort4(threadgroupSize, 0, ushort(dummyVal % 255)), position);
}

kernel void fill_with_threadgroup_size_even(texture2d<ushort, access::write> output [[ texture(0) ]],
                                             ushort2 position [[ thread_position_in_grid]],
                                             ushort2 threadgroupSize [[threads_per_threadgroup]]) {
    if (position.x >= output.get_width() || position.y >= output.get_height()) {
        return;
    }

    uint dummyVal = 0;
    for (int i = 0; i < 10000000; i++) {
        dummyVal += position.y;
    }

    output.write(ushort4(threadgroupSize, 0, ushort(dummyVal % 255)), position);
}

kernel void switchDataFormat(texture2d<float, access::read_write> normalizedTexture [[ texture(0) ]],
                             texture2d<uint, access::read_write> unnormalizedTexture [[ texture(1) ]],
                             const ushort2 position [[thread_position_in_grid]]) {
    const ushort2 textureSize = ushort2(normalizedTexture.get_width(),
                                        normalizedTexture.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    if (conversionTypeDenormalize) {
        float4 floatValue = normalizedTexture.read(position);
        uint4 uintValue = uint4(floatValue * 255);
        unnormalizedTexture.write(uintValue, position);
    } else {
        uint4 uintValue = unnormalizedTexture.read(position);
        float4 floatValue = float4(uintValue) / 255;
        normalizedTexture.write(floatValue, position);
    }
}
