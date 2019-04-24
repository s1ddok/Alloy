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

constant bool deviceSupportsNonuniformThreadgroups [[function_constant(0)]];

struct BlockSize {
    ushort width;
    ushort height;
};

kernel void textureCopy(texture2d<half, access::read> texture_1 [[ texture(0) ]],
                        texture2d<half, access::write> texture_2 [[ texture(1) ]],
                        const ushort2 position [[ thread_position_in_grid ]]) {

    const ushort inputTextureWidth = texture_1.get_width();
    const ushort inputTextureHeight = texture_1.get_height();

    if (!deviceSupportsNonuniformThreadgroups) {
        if (position.x >= inputTextureWidth || position.y >= inputTextureHeight) {
            return;
        }
    }

    const half4 c_1 = texture_1.read(position);

    texture_2.write(c_1, position);
}

kernel void max(texture2d<half, access::sample> inputTexture [[ texture(0) ]],
                constant BlockSize& inputBlockSize [[ buffer(0) ]],
                device float4& result [[ buffer(1) ]],
                threadgroup half4* sharedMemory [[ threadgroup(0) ]],
                const ushort index [[ thread_index_in_threadgroup ]],
                const ushort2 position [[ thread_position_in_grid ]],
                const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]]) {

    const ushort2 inputTextureSize = ushort2(inputTexture.get_width(), inputTexture.get_height());

    ushort2 originalBlockSize = ushort2(inputBlockSize.width, inputBlockSize.height);
    const ushort2 blockStartPosition = position * originalBlockSize;

    ushort2 blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const ushort2 readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - inputTextureSize);
    }

    half4 maxValueInBlock = inputTexture.read(blockStartPosition);

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const ushort2 readPosition = blockStartPosition + ushort2(x, y);
            const half4 currentValue = inputTexture.read(readPosition);
            maxValueInBlock = max(maxValueInBlock, currentValue);
        }
    }

    sharedMemory[index] = maxValueInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {

        half4 maxValue = sharedMemory[0];
        const ushort threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            half4 maxValueInBlock = sharedMemory[i];
            maxValue = max(maxValue, maxValueInBlock);
        }

        result = float4(maxValue);
    }

}

kernel void min(texture2d<half, access::sample> inputTexture [[ texture(0) ]],
                constant BlockSize& inputBlockSize [[ buffer(0) ]],
                device float4& result [[ buffer(1) ]],
                threadgroup half4* sharedMemory [[ threadgroup(0) ]],
                const ushort index [[ thread_index_in_threadgroup ]],
                const ushort2 position [[ thread_position_in_grid ]],
                const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]]) {

    const ushort2 inputTextureSize = ushort2(inputTexture.get_width(), inputTexture.get_height());

    ushort2 originalBlockSize = ushort2(inputBlockSize.width, inputBlockSize.height);
    const ushort2 blockStartPosition = position * originalBlockSize;

    ushort2 blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const ushort2 readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - inputTextureSize);
    }

    half4 minValueInBlock = inputTexture.read(blockStartPosition);

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const ushort2 readPosition = blockStartPosition + ushort2(x, y);
            const half4 currentValue = inputTexture.read(readPosition);
            minValueInBlock = min(minValueInBlock, currentValue);
        }
    }

    sharedMemory[index] = minValueInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {

        half4 minValue = sharedMemory[0];
        const ushort threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            half4 minValueInBlock = sharedMemory[i];
            minValue = min(minValue, minValueInBlock);
        }

        result = float4(minValue);
    }

}

kernel void mean(texture2d<half, access::sample> inputTexture [[ texture(0) ]],
                 constant BlockSize& inputBlockSize [[ buffer(0) ]],
                 device float4& result [[ buffer(1) ]],
                 threadgroup half4* sharedMemory [[ threadgroup(0) ]],
                 const ushort index [[ thread_index_in_threadgroup ]],
                 const ushort2 position [[ thread_position_in_grid ]],
                 const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]]) {

    const ushort2 inputTextureSize = ushort2(inputTexture.get_width(), inputTexture.get_height());

    ushort2 originalBlockSize = ushort2(inputBlockSize.width, inputBlockSize.height);
    const ushort2 blockStartPosition = position * originalBlockSize;

    ushort2 blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const ushort2 readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - inputTextureSize);
    }

    half4 totalSumInBlock = half4(0, 0, 0, 0);

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const ushort2 readPosition = blockStartPosition + ushort2(x, y);
            const half4 currentValue = inputTexture.read(readPosition);
            totalSumInBlock += currentValue;
        }
    }

    sharedMemory[index] = totalSumInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {

        half4 totalSum = sharedMemory[0];
        const ushort threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            half4 totalSumInBlock = sharedMemory[i];
            totalSum += totalSumInBlock;
        }

        half gridSize = inputTexture.get_width() * inputTexture.get_height();
        half4 meanValue = totalSum / gridSize;

        result = float4(meanValue);
    }

}
