//
//  Shaders.metal
//  AIBeauty
//
//  Created by Andrey Volodin on 08.08.2018.
//  Copyright © 2018 Andrey Volodin. All rights reserved.
//

#include <metal_stdlib>
#include "ColorConversion.h"
#include "ShaderStructures.h"
#include "Definitions.h"

using namespace metal;

constant bool deviceSupportsNonuniformThreadgroups [[function_constant(0)]];

struct BlockSize {
    ushort width;
    ushort height;
};

// MARK: - General Purpose

kernel void textureCopy(texture2d<half, access::read> texture_1 [[ texture(0) ]],
                        texture2d<half, access::write> texture_2 [[ texture(1) ]],
                        const ushort2 thread_position_in_grid [[thread_position_in_grid]]) {

    const ushort input_texture_width = texture_1.get_width();
    const ushort input_texture_height = texture_1.get_height();

    if (!deviceSupportsNonuniformThreadgroups) {
        if (thread_position_in_grid.x >= input_texture_width || thread_position_in_grid.y >= input_texture_height) {
            return;
        }
    }

    const half4 c_1 = texture_1.read(thread_position_in_grid);

    texture_2.write(c_1, thread_position_in_grid);
}

kernel void textureMask(texture2d<half, access::read> inputTexture [[ texture(0) ]],
                        texture2d<half, access::sample> mask [[ texture(1) ]],
                        texture2d<half, access::write> outputTexture [[ texture(2) ]],
                        const ushort2 thread_position_in_grid [[thread_position_in_grid]]) {
    const ushort inputWidth = inputTexture.get_width();
    const ushort inputHeight = inputTexture.get_height();

    if (!deviceSupportsNonuniformThreadgroups) {
        if (thread_position_in_grid.x >= inputWidth || thread_position_in_grid.y >= inputHeight) {
            return;
        }
    }

    const half4 originalPixel = inputTexture.read(thread_position_in_grid);

    constexpr sampler s(coord::normalized,
                        address::clamp_to_zero,
                        filter::linear);

    const half4 maskValue = mask.sample(s, (float2(thread_position_in_grid) + 0.5) / float2(inputWidth, inputHeight));

    const half4 maskedPixel = originalPixel * maskValue.r;

    outputTexture.write(maskedPixel, thread_position_in_grid);
}


kernel void textureSum(texture2d<half, access::read> inputTexture1 [[ texture(0) ]],
                       texture2d<half, access::read> inputTexture2 [[ texture(1) ]],
                       texture2d<half, access::write> outputTexture [[ texture(2) ]],
                       const ushort2 thread_position_in_grid [[thread_position_in_grid]]) {
    const ushort inputWidth = inputTexture1.get_width();
    const ushort inputHeight = inputTexture1.get_height();

    if (!deviceSupportsNonuniformThreadgroups) {
        if (thread_position_in_grid.x >= inputWidth || thread_position_in_grid.y >= inputHeight) {
            return;
        }
    }

    const half4 inputPixel1 = inputTexture1.read(thread_position_in_grid);
    const half4 inputPixel2 = inputTexture2.read(thread_position_in_grid);

    outputTexture.write(inputPixel1 + inputPixel2, thread_position_in_grid);
}


// MARK: - Texture Max

template <typename T>
void textureMax(texture2d<T, access::read> sourceTexture,
                constant BlockSize& inputBlockSize,
                device float4& result,
                threadgroup float4* sharedMemory,
                const ushort index,
                const ushort2 position,
                const ushort2 threadsPerThreadgroup) {
    const ushort2 textureSize = ushort2(sourceTexture.get_width(),
                                        sourceTexture.get_height());

    ushort2 originalBlockSize = ushort2(inputBlockSize.width,
                                        inputBlockSize.height);
    const ushort2 blockStartPosition = position * originalBlockSize;

    ushort2 block_size = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const ushort2 readTerritory = blockStartPosition + originalBlockSize;
        block_size = originalBlockSize - (readTerritory - textureSize);
    }

    float4 maxValueInBlock = float4(sourceTexture.read(blockStartPosition));

    for (ushort x = 0; x < block_size.x; x++) {
        for (ushort y = 0; y < block_size.y; y++) {
            const ushort2 readPosition = blockStartPosition + ushort2(x, y);
            const float4 currentValue = float4(sourceTexture.read(readPosition));
            maxValueInBlock = max(maxValueInBlock, currentValue);
        }
    }

    sharedMemory[index] = maxValueInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {

        auto maxValue = sharedMemory[0];
        const ushort threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            float4 maxValueInBlock = sharedMemory[i];
            maxValue = max(maxValue, maxValueInBlock);
        }

        result = maxValue;
    }
}

kernel void min(texture2d<half, access::sample> input_texture [[ texture(0) ]],
                constant BlockSize& input_block_size [[ buffer(0) ]],
                device float4& result [[ buffer(1) ]],
                threadgroup half4* shared_memory [[ threadgroup(0) ]],
                const ushort thread_index_in_threadgroup [[ thread_index_in_threadgroup ]],
                const ushort2 thread_position_in_grid [[ thread_position_in_grid ]],
                const ushort2 threads_per_threadgroup [[ threads_per_threadgroup ]]) {
    const ushort2 input_texture_size = ushort2(input_texture.get_width(), input_texture.get_height());

    ushort2 original_block_size = ushort2(input_block_size.width, input_block_size.height);
    const ushort2 block_start_position = thread_position_in_grid * original_block_size;

    ushort2 block_size = original_block_size;
    if (thread_position_in_grid.x == threads_per_threadgroup.x || thread_position_in_grid.y == threads_per_threadgroup.y) {
        const ushort2 read_territory = block_start_position + original_block_size;
        block_size = original_block_size - (read_territory - input_texture_size);
#define outerArguments(T)                                          \
(texture2d<T, access::read> sourceTexture [[ texture(0) ]],        \
constant BlockSize& inputBlockSize [[ buffer(0) ]],                \
device float4& result [[ buffer(1) ]],                             \
threadgroup float4* sharedMemory [[ threadgroup(0) ]],             \
const ushort index [[ thread_index_in_threadgroup ]],              \
const ushort2 position [[ thread_position_in_grid ]],              \
const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]]) \

#define innerArguments \
(sourceTexture,        \
inputBlockSize,        \
result,                \
sharedMemory,          \
index,                 \
position,              \
threadsPerThreadgroup) \

generateKernels(textureMax)

#undef outerArguments
#undef innerArguments
    }

    half4 min_value_in_block = input_texture.read(block_start_position);

    for (ushort x = 0; x < block_size.x; x++) {
        for (ushort y = 0; y < block_size.y; y++) {
            const ushort2 read_position = block_start_position + ushort2(x, y);
            const half4 current_value = input_texture.read(read_position);
            min_value_in_block = min(min_value_in_block, current_value);
        }
    }

    shared_memory[thread_index_in_threadgroup] = min_value_in_block;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (thread_index_in_threadgroup == 0) {

        half4 min_value = shared_memory[0];
        const ushort threads_in_threadgroup = threads_per_threadgroup.x * threads_per_threadgroup.y;
        for (ushort i = 1; i < threads_in_threadgroup; i++) {
            half4 min_value_in_block = shared_memory[i];
            min_value = min(min_value, min_value_in_block);
        }

        result = float4(min_value);
    }

}

kernel void mean(texture2d<half, access::sample> input_texture [[ texture(0) ]],
                 constant BlockSize& input_block_size [[ buffer(0) ]],
                 device float4& result [[ buffer(1) ]],
                 threadgroup half4* shared_memory [[ threadgroup(0) ]],
                 const ushort thread_index_in_threadgroup [[ thread_index_in_threadgroup ]],
                 const ushort2 thread_position_in_grid [[ thread_position_in_grid ]],
                 const ushort2 threads_per_threadgroup [[ threads_per_threadgroup ]]) {
    const ushort2 input_texture_size = ushort2(input_texture.get_width(), input_texture.get_height());

    ushort2 original_block_size = ushort2(input_block_size.width, input_block_size.height);
    const ushort2 block_start_position = thread_position_in_grid * original_block_size;

    ushort2 block_size = original_block_size;
    if (thread_position_in_grid.x == threads_per_threadgroup.x || thread_position_in_grid.y == threads_per_threadgroup.y) {
        const ushort2 read_territory = block_start_position + original_block_size;
        block_size = original_block_size - (read_territory - input_texture_size);
    }

    half4 total_sum_in_block = half4(0, 0, 0, 0);

    for (ushort x = 0; x < block_size.x; x++) {
        for (ushort y = 0; y < block_size.y; y++) {
            const ushort2 read_position = block_start_position + ushort2(x, y);
            const half4 current_value = input_texture.read(read_position);
            total_sum_in_block += current_value;
        }
    }

    shared_memory[thread_index_in_threadgroup] = total_sum_in_block;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (thread_index_in_threadgroup == 0) {

        half4 total_sum = shared_memory[0];
        const ushort threads_in_threadgroup = threads_per_threadgroup.x * threads_per_threadgroup.y;
        for (ushort i = 1; i < threads_in_threadgroup; i++) {
            half4 total_sum_in_block = shared_memory[i];
            total_sum += total_sum_in_block;
        }

        half grid_size = input_texture.get_width() * input_texture.get_height();
        half4 mean_value = total_sum / grid_size;

        result = float4(mean_value);
    }

}

// MARK: - Mask Guided Blur

kernel void maskGuidedBlurRowPass(texture2d<float, access::read> sourceTexture [[ texture(0) ]],
                                  texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                                  texture2d<float, access::write> destinationTexture [[ texture(2) ]],
                                  constant float& sigma [[ buffer(0) ]],
                                  ushort2 position [[thread_position_in_grid]]) {
    const ushort sourceTextureWidth = sourceTexture.get_width();
    const ushort sourceTextureHeight = sourceTexture.get_height();

    if (!deviceSupportsNonuniformThreadgroups) {
        if (position.x >= sourceTextureWidth || position.y >= sourceTextureHeight) {
            return;
        }
    }

    constexpr sampler s(filter::linear, coord::normalized);

    const float2 srcTid = float2(float(position.x) / sourceTextureWidth,
                                 float(position.y) / sourceTextureHeight);

    const float maskValue = maskTexture.sample(s, srcTid).r;

    const float sigma_ = (1.0f - maskValue) * sigma;
    const int kernelRadius = int(2.0f * sigma_);

    float normalizingConstant = 0.0f;
    float3 result = float3(0.0f);

    for (int drow = -kernelRadius; drow <= kernelRadius; drow++) {
        const float kernelValue = exp(float(-drow * drow) / (2.0f * sigma_ * sigma_ + 1e-5f));
        const uint2 coordinate = uint2(clamp(int(position.x) + drow, 0, sourceTextureWidth - 1),
                                       position.y);
        const float2 maskTid = float2(float(coordinate.x) / sourceTextureWidth,
                                      float(coordinate.y) / sourceTextureHeight);
        const float maskMultiplier = 1.0f - maskTexture.sample(s, maskTid).r + 1e-5f;
        const float totalFactor = kernelValue * maskMultiplier;
        normalizingConstant += totalFactor;
        result += sourceTexture.read(coordinate).rgb * totalFactor;
    }

    result /= normalizingConstant;

    destinationTexture.write(float4(result, 1.0f), position);
}

kernel void maskGuidedBlurColumnPass(texture2d<float, access::read> sourceTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                                     texture2d<float, access::write> destinationTexture [[ texture(2) ]],
                                     constant float& sigma [[ buffer(0) ]],
                                     ushort2 position [[thread_position_in_grid]]) {
    const ushort sourceTextureWidth = sourceTexture.get_width();
    const ushort sourceTextureHeight = sourceTexture.get_height();

    if (!deviceSupportsNonuniformThreadgroups) {
        if (position.x >= sourceTextureWidth || position.y >= sourceTextureHeight) {
            return;
        }
    }

    constexpr sampler s(filter::linear, coord::normalized);

    const float2 srcTid = float2(float(position.x) / sourceTextureWidth,
                                 float(position.y) / sourceTextureHeight);

    const float maskValue = maskTexture.sample(s, srcTid).r;

    const float sigma_ = (1.0f - maskValue) * sigma;
    const int kernelRadius = int(2.0f * sigma_);

    float normalizingConstant = 0.0f;
    float3 result = float3(0.0f);

    for (int dcol = -kernelRadius; dcol <= kernelRadius; dcol++) {
        const float kernelValue = exp(float(-dcol * dcol) / (2.0f * sigma_ * sigma_ + 1e-5f));
        const uint2 coordinate = uint2(position.x,
                                       clamp(int(position.y) + dcol, 0, sourceTextureHeight - 1));
        const float2 maskTid = float2(float(coordinate.x) / sourceTextureWidth,
                                      float(coordinate.y) / sourceTextureHeight);
        const float maskMultiplier = 1.0f - maskTexture.sample(s, maskTid).r + 1e-5f;
        const float totalFactor = kernelValue * maskMultiplier;
        normalizingConstant += totalFactor;
        result += sourceTexture.read(coordinate).rgb * totalFactor;
    }

    result /= normalizingConstant;

    destinationTexture.write(float4(result, 1.0f), position);
}

float euclideanDistance(float4 firstValue, float4 secondValue) {
    const float4 diff = firstValue - secondValue;
    return sqrt(dot(pow(diff, 2), 1));
}

template <typename T>
void euclideanDistance(texture2d<T, access::sample> textureOne,
                       texture2d<T, access::sample> textureTwo,
                       constant BlockSize& inputBlockSize,
                       device float& result,
                       threadgroup float* sharedMemory,
                       const ushort index,
                       const ushort2 position,
                       const ushort2 threadsPerThreadgroup) {
    const ushort2 textureSize = ushort2(textureOne.get_width(),
                                        textureOne.get_height());

    ushort2 originalBlockSize = ushort2(inputBlockSize.width,
                                        inputBlockSize.height);
    const ushort2 blockStartPosition = position * originalBlockSize;

    ushort2 blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const ushort2 readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - textureSize);
    }

    float euclideanDistanceSumInBlock = 0.0f;

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const ushort2 readPosition = blockStartPosition + ushort2(x, y);
            const float4 textureOneValue = float4(textureOne.read(readPosition));
            const float4 textureTwoValue = float4(textureTwo.read(readPosition));
            euclideanDistanceSumInBlock += euclideanDistance(textureOneValue,
                                                             textureTwoValue);
        }
    }

    sharedMemory[index] = euclideanDistanceSumInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {
        float totalEuclideanDistanceSum = sharedMemory[0];
        const ushort threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            totalEuclideanDistanceSum += sharedMemory[i];
        }

        result = totalEuclideanDistanceSum;
    }

}

#define outerArguments(T)                                          \
(texture2d<T, access::sample> textureOne [[ texture(0) ]],         \
texture2d<T, access::sample> textureTwo [[ texture(1) ]],          \
constant BlockSize& inputBlockSize [[ buffer(0) ]],                \
device float& result [[ buffer(1) ]],                              \
threadgroup float* sharedMemory [[ threadgroup(0) ]],              \
const ushort index [[ thread_index_in_threadgroup ]],              \
const ushort2 position [[ thread_position_in_grid ]],              \
const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]])

#define innerArguments \
(textureOne,           \
textureTwo,            \
inputBlockSize,        \
result,                \
sharedMemory,          \
index,                 \
position,              \
threadsPerThreadgroup)

generateKernels(euclideanDistance)

#undef outerArguments
#undef innerArguments

template <typename T>
void addConstant(texture2d<T, access::read> sourceTexture,
                 texture2d<T, access::write> destinationTexture,
                 constant float4& constantValue,
                 const ushort2 position) {
    const ushort2 textureSize = ushort2(sourceTexture.get_width(),
                                        sourceTexture.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    auto sourceTextureValue = sourceTexture.read(position);
    auto destinationTextureValue = sourceTextureValue + vec<T, 4>(constantValue);
    destinationTexture.write(destinationTextureValue, position);
}

#define outerArguments(T)                                        \
(texture2d<T, access::read> sourceTexture [[ texture(0) ]],      \
texture2d<T, access::write> destinationTexture [[ texture(1) ]], \
constant float4& constantValue [[ buffer(0) ]],                  \
const ushort2 position [[ thread_position_in_grid ]])

#define innerArguments \
(sourceTexture,        \
destinationTexture,    \
constantValue,         \
position)

generateKernels(addConstant)

#undef outerArguments
#undef innerArguments

// MARK: - ML

kernel void normalize(texture2d<half, access::read> inputTexture [[ texture(0) ]],
                      texture2d<half, access::write> outputTexture [[ texture(1) ]],
                      constant float3& mean [[ buffer(0) ]],
                      constant float3& std [[ buffer(1) ]],
                      uint2 position [[thread_position_in_grid]]) {
    const ushort2 textureSize = ushort2(inputTexture.get_width(),
                                        inputTexture.get_height());
    if (!deviceSupportsNonuniformThreadgroups) {
        if (position.x >= textureSize.x || position.y >= textureSize.y) {
            return;
        }
    }
    // Read mpsnngraph result value.
    const half4 originalValue = inputTexture.read(position);
    const half3 meanValue = (half3)mean;
    const half3 stdValue = (half3)std;
    half4 normalizedValue = originalValue;
    normalizedValue.rgb -= meanValue;
    normalizedValue.rgb /= stdValue;
    outputTexture.write(normalizedValue, position);
}

// MARK: - Rendering

float2 perpendicular(float2 vector) {
    return float2(-vector.y, vector.x);
}

float2 convertToScreenSpace(float2 vector) {
    return float2(-1 + (vector.x * 2),
                  -1 + ((1 - vector.y) * 2));
}

// MARK: - Rectangle Rendering

struct VertexOut {
    float4 position [[ position ]];
};

vertex VertexOut rectVertex(constant Rectangle& rectangle [[ buffer(0) ]],
                            uint vid [[vertex_id]]) {
    const float2 positions[] = {
        rectangle.topLeft, rectangle.bottomLeft,
        rectangle.topRight, rectangle.bottomRight
    };

    VertexOut out;
    float2 position = convertToScreenSpace(positions[vid]);
    out.position = float4(position, 0.0, 1.0);

    return out;
}

fragment float4 primitivesFragment(VertexOut in [[ stage_in ]],
                                   constant float4& color [[ buffer(0) ]]) {
    return color;
}

// MARK: - Mask Rendering

struct MaskVertexOut {
    float4 position [[ position ]];
    float2 uv;
};

vertex MaskVertexOut maskVertex(constant Rectangle& rectangle [[ buffer(0) ]],
                                uint vid [[vertex_id]]) {
    struct Vertex {
        float2 position;
        float2 uv;
    };

    const Vertex vertices[] = {
        Vertex { rectangle.topLeft, float2(0.0, 1.0) },
        Vertex { rectangle.bottomLeft, float2(0.0, 0.0) },
        Vertex { rectangle.topRight, float2(1.0, 1.0) },
        Vertex { rectangle.bottomRight, float2(1.0, 0.0) }
    };

    MaskVertexOut out;
    float2 position = convertToScreenSpace(vertices[vid].position);
    out.position = float4(position, 0.0, 1.0);
    out.uv = vertices[vid].uv;

    return out;
}

fragment float4 maskFragment(MaskVertexOut in [[ stage_in ]],
                              texture2d<half, access::sample> maskTexture [[ texture(0) ]],
                              constant float4& color [[ buffer(0) ]]) {
    constexpr sampler s(coord::normalized,
                        address::clamp_to_zero,
                        filter::linear);
    float4 maskValue = (float4)maskTexture.sample(s, in.uv).rrrr;
    float4 resultColor = maskValue * color;

    return resultColor;
}

// MARK: - Lines Rendering

vertex VertexOut linesVertex(constant Line *lines [[ buffer(0) ]],
                             uint vertexId [[vertex_id]],
                             uint instanceId [[instance_id]]) {
    Line line = lines[instanceId];

    float2 startPoint = line.startPoint;
    float2 endPoint = line.endPoint;

    float2 vector = startPoint - endPoint;
    float2 perpendicularVector = perpendicular(normalize(vector));
    float halfWidth = line.width / 2;

    struct PositionAndOffsetFactor {
        float2 vertexPosition;
        float offsetFactor;
    };

    const PositionAndOffsetFactor positionsAndOffsetFactors[] = {
        PositionAndOffsetFactor { startPoint, -1.0 },
        PositionAndOffsetFactor { endPoint, -1.0 },
        PositionAndOffsetFactor { startPoint, 1.0 },
        PositionAndOffsetFactor { endPoint, 1.0 }
    };

    VertexOut out;
    const float2 vertexPosition = positionsAndOffsetFactors[vertexId].vertexPosition;
    const float offsetFactor = positionsAndOffsetFactors[vertexId].offsetFactor;
    float2 position = convertToScreenSpace(vertexPosition + offsetFactor * perpendicularVector * halfWidth);
    out.position = float4(position, 0.0, 1.0);

    return out;
}

// MARK: - Points Rendering

struct PointVertexOut {
    float4 position [[ position ]];
    float size [[ point_size ]];
};

vertex PointVertexOut pointVertex(constant float2* pointsPositions [[ buffer(0) ]],
                                  constant float& pointSize [[ buffer(1) ]],
                                  uint instanceId [[instance_id]]) {
    const float2 pointPosition = pointsPositions[instanceId];

    PointVertexOut out;
    float2 position = convertToScreenSpace(pointPosition);
    out.position = float4(position, 0, 1);
    out.size = pointSize;

    return out;
}

fragment float4 pointFragment(PointVertexOut in [[stage_in]],
                              const float2 pointCenter [[ point_coord ]],
                              constant float4& pointColor [[ buffer(0) ]]) {
    const float distanceFromCenter = length(2 * (pointCenter - 0.5));
    float4 color = pointColor;
    color.a = 1.0 - smoothstep(0.9, 1.0, distanceFromCenter);

    return color;
}

vertex float4 simpleVertex(constant float4* vertices [[ buffer(0) ]],
                           constant float4x4& matrix [[ buffer(1) ]],
                           uint vid [[vertex_id]]) {
    const float4 v = vertices[vid];

    return matrix * v;
}

fragment float4 plainColorFragment(constant float4& pointColor [[ buffer(0) ]]) {
    return pointColor;
}
