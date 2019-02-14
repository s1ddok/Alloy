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

constant bool device_supports_features_of_gpu_family4_v1 [[function_constant(0)]];

struct BlockSize {
    ushort width;
    ushort height;
};

kernel void textureCopy(texture2d<half, access::read> texture_1 [[ texture(0) ]],
                        texture2d<half, access::write> texture_2 [[ texture(1) ]],
                        const ushort2 position [[thread_position_in_grid]]) {
    if (!device_supports_features_of_gpu_family4_v1) {
        if (position.x >= texture_1.get_width() || position.y >= texture_1.get_height()) {
            return;
        }
    }

    const half4 c_1 = texture_1.read(position);

    texture_2.write(c_1, position);
}

kernel void max(texture2d<half, access::sample> input_texture [[ texture(0) ]],
                constant BlockSize& block_size [[ buffer(0) ]],
                device float4& result [[ buffer(1) ]],
                threadgroup half4* shared_memory [[ threadgroup(0) ]],
                const ushort tiit [[ thread_index_in_threadgroup ]],
                const ushort2 tpig [[ thread_position_in_grid ]],
                const ushort2 tpt [[ threads_per_threadgroup ]]) {
    constexpr sampler s(coord::pixel,
                        address::clamp_to_zero,
                        filter::nearest);

    half4 max_value_in_block = 0;

    for (ushort x = 0; x < block_size.width; x++) {
        for (ushort y = 0; y < block_size.height; y++) {

            ushort2 block_size_coef = ushort2(block_size.width, block_size.height);
            const float2 read_position = float2(tpig * block_size_coef + ushort2(x, y));

            // Prevent going out of texture.
            if (read_position.x >= input_texture.get_width() || read_position.y >= input_texture.get_height()) {
                break;
            }

            const half4 current_value = input_texture.sample(s, read_position);
            max_value_in_block = max(max_value_in_block, current_value);
        }
    }

    shared_memory[tiit] = max_value_in_block;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (tiit == 0) {

        half4 max_value = shared_memory[0];
        const ushort threads_in_threadgroup = tpt.x * tpt.y;
        for (ushort i = 1; i < threads_in_threadgroup; i++) {
            half4 max_value_in_block = shared_memory[i];
            max_value = max(max_value, max_value_in_block);
        }

        result = float4(max_value);
    }

}

kernel void min(texture2d<half, access::sample> input_texture [[ texture(0) ]],
                constant BlockSize& block_size [[ buffer(0) ]],
                device float4& result [[ buffer(1) ]],
                threadgroup half4* shared_memory [[ threadgroup(0) ]],
                const ushort tiit [[ thread_index_in_threadgroup ]],
                const ushort2 tpig [[ thread_position_in_grid ]],
                const ushort2 tpt [[ threads_per_threadgroup ]]) {
    constexpr sampler s(coord::pixel,
                        address::clamp_to_zero,
                        filter::nearest);

    half4 min_value_in_block = input_texture.sample(s, float2(0, 0));

    for (ushort x = 0; x < block_size.width; x++) {
        for (ushort y = 0; y < block_size.height; y++) {

            ushort2 block_size_coef = ushort2(block_size.width, block_size.height);
            const float2 read_position = float2(tpig * block_size_coef + ushort2(x, y));

            // Prevent going out of texture.
            if (read_position.x >= input_texture.get_width() || read_position.y >= input_texture.get_height()) {
                break;
            }

            const half4 current_value = input_texture.sample(s, read_position);
            min_value_in_block = min(min_value_in_block, current_value);
        }
    }

    shared_memory[tiit] = min_value_in_block;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (tiit == 0) {

        half4 min_value = shared_memory[0];
        const ushort threads_in_threadgroup = tpt.x * tpt.y;
        for (ushort i = 1; i < threads_in_threadgroup; i++) {
            half4 min_value_in_block = shared_memory[i];
            min_value = min(min_value, min_value_in_block);
        }

        result = float4(min_value);
    }

}

kernel void mean(texture2d<half, access::sample> input_texture [[ texture(0) ]],
                 constant BlockSize& block_size [[ buffer(0) ]],
                 device float4& result [[ buffer(1) ]],
                 threadgroup half4* shared_memory [[ threadgroup(0) ]],
                 const ushort tiit [[ thread_index_in_threadgroup ]],
                 const ushort2 tpig [[ thread_position_in_grid ]],
                 const ushort2 tpt [[ threads_per_threadgroup ]]) {
    constexpr sampler s(coord::pixel,
                        address::clamp_to_zero,
                        filter::nearest);

    half4 total_sum_in_block = input_texture.sample(s, float2(0, 0));

    for (ushort x = 0; x < block_size.width; x++) {
        for (ushort y = 0; y < block_size.height; y++) {

            ushort2 block_size_coef = ushort2(block_size.width, block_size.height);
            const float2 read_position = float2(tpig * block_size_coef + ushort2(x, y));

            // Prevent going out of texture.
            if (read_position.x >= input_texture.get_width() || read_position.y >= input_texture.get_height()) {
                break;
            }

            const half4 current_value = input_texture.sample(s, read_position);
            total_sum_in_block += current_value;
        }
    }

    shared_memory[tiit] = total_sum_in_block;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (tiit == 0) {

        half4 total_sum = shared_memory[0];
        const ushort threads_in_threadgroup = tpt.x * tpt.y;
        for (ushort i = 1; i < threads_in_threadgroup; i++) {
            half4 total_sum_in_block = shared_memory[i];
            total_sum += total_sum_in_block;
        }

        half grid_size = input_texture.get_width() * input_texture.get_height();
        half4 mean_value = total_sum / grid_size;

        result = float4(mean_value);
    }

}



kernel void dummy() {}
