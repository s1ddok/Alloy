#include <metal_stdlib>
#include "ColorConversion.h"
#include "Definitions.h"
#include "../../AlloyShadersSharedTypes/AlloyShadersSharedTypes.h"

using namespace metal;

constant bool deviceSupportsNonuniformThreadgroups [[ function_constant(0) ]];
constant bool deviceDoesntSupportNonuniformThreadgroups = !deviceSupportsNonuniformThreadgroups;
constant float multiplierFC [[ function_constant(1) ]];
constant bool halfSizedCbCr [[ function_constant(2) ]];

struct BlockSize {
    ushort width;
    ushort height;
};

// MARK: - General Purpose

// MARK: - Texture Copy

template <typename T>
void textureCopy(texture2d<T, access::read> source,
                 texture2d<T, access::write> destination,
                 constant short2& readOffset,
                 constant short2& writeOffset,
                 constant ushort2& gridSize,
                 const ushort2 position) {
    checkPosition(position, gridSize, deviceSupportsNonuniformThreadgroups);

    const auto readPosition = ushort2(short2(position) + readOffset);
    const auto writePosition = ushort2(short2(position) + writeOffset);

    const auto resultValue = source.read(readPosition);
    destination.write(resultValue, writePosition);
}

#define outerArguments(T)                                        \
(texture2d<T, access::read> source [[ texture(0) ]],             \
texture2d<T, access::write> destination [[ texture(1) ]],        \
constant short2& readOffset [[ buffer(0) ]],                     \
constant short2& writeOffset [[ buffer(1) ]],                    \
constant ushort2& gridSize [[ buffer(2),                         \
function_constant(deviceDoesntSupportNonuniformThreadgroups) ]], \
const ushort2 position [[ thread_position_in_grid ]])            \

#define innerArguments \
(source,               \
destination,           \
readOffset,            \
writeOffset,           \
gridSize,              \
position)              \

generateKernels(textureCopy)

#undef outerArguments
#undef innerArguments

// MARK: - Resize Texture

kernel void textureResize(texture2d<float, access::sample> source [[ texture(0) ]],
                          texture2d<float, access::write> destination [[ texture(1) ]],
                          sampler s [[ sampler(0) ]],
                          const ushort2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    const auto positionF = float2(position);
    const auto textureSizeF = float2(textureSize);
    const auto normalizedPosition = (positionF + 0.5f) / textureSizeF;

    auto sampledValue = source.sample(s, normalizedPosition);
    destination.write(sampledValue, position);
}

// MARK: - Texture Mask

template <typename T>
void textureMask(texture2d<T, access::read> source,
                 texture2d<float, access::sample> mask,
                 texture2d<T, access::write> destination,
                 constant bool& isInversed,
                 const ushort2 position) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    const auto sourceValue = float4(source.read(position));

    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);
    const auto positionF = float2(position);
    const auto textureSizeF = float2(textureSize);
    const auto normalizedPosition = (positionF + 0.5f) / textureSizeF;

    auto maskValue = mask.sample(s, normalizedPosition);
    if (isInversed) {
        maskValue = 1.0f - maskValue;
    }
    const auto resultValue = vec<T, 4>(sourceValue * maskValue.r);

    destination.write(resultValue, position);
}

#define outerArguments(T)                                 \
(texture2d<T, access::read> source [[ texture(0) ]],      \
texture2d<float, access::sample> mask [[ texture(1) ]],   \
texture2d<T, access::write> destination [[ texture(2) ]], \
constant bool& isInversed [[ buffer(0) ]],                \
const ushort2 position [[thread_position_in_grid]])       \

#define innerArguments \
(source,               \
mask,                  \
destination,           \
isInversed,            \
position)              \

generateKernels(textureMask)

#undef outerArguments
#undef innerArguments

// MARK: - Texture Max

template <typename T>
void textureMax(texture2d<T, access::read> source,
                constant BlockSize& inputBlockSize,
                device float4& result,
                threadgroup float4* sharedMemory,
                const ushort index,
                const ushort2 position,
                const ushort2 threadsPerThreadgroup) {
    const auto textureSize = ushort2(source.get_width(),
                                     source.get_height());

    const auto originalBlockSize = ushort2(inputBlockSize.width,
                                           inputBlockSize.height);
    const auto blockStartPosition = position * originalBlockSize;

    auto blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const auto readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - textureSize);
    }

    auto maxValueInBlock = float4(source.read(blockStartPosition));

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const auto readPosition = blockStartPosition + ushort2(x, y);
            const auto currentValue = float4(source.read(readPosition));
            maxValueInBlock = max(maxValueInBlock, currentValue);
        }
    }

    sharedMemory[index] = maxValueInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {
        auto maxValue = sharedMemory[0];
        const auto threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            maxValue = max(maxValue, sharedMemory[i]);
        }
        result = maxValue;
    }
}

#define outerArguments(T)                                          \
(texture2d<T, access::read> source [[ texture(0) ]],               \
constant BlockSize& inputBlockSize [[ buffer(0) ]],                \
device float4& result [[ buffer(1) ]],                             \
threadgroup float4* sharedMemory [[ threadgroup(0) ]],             \
const ushort index [[ thread_index_in_threadgroup ]],              \
const ushort2 position [[ thread_position_in_grid ]],              \
const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]]) \

#define innerArguments \
(source,               \
inputBlockSize,        \
result,                \
sharedMemory,          \
index,                 \
position,              \
threadsPerThreadgroup) \

generateKernels(textureMax)

#undef outerArguments
#undef innerArguments

// MARK: - Texture Min

template <typename T>
void textureMin(texture2d<T, access::read> source,
                constant BlockSize& inputBlockSize,
                device float4& result,
                threadgroup float4* sharedMemory,
                const ushort index,
                const ushort2 position,
                const ushort2 threadsPerThreadgroup) {
    const auto textureSize = ushort2(source.get_width(),
                                     source.get_height());

    auto originalBlockSize = ushort2(inputBlockSize.width,
                                     inputBlockSize.height);
    const auto blockStartPosition = position * originalBlockSize;

    auto blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const auto readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - textureSize);
    }

    auto minValueInBlock = float4(source.read(blockStartPosition));

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const auto readPosition = blockStartPosition + ushort2(x, y);
            const auto currentValue = float4(source.read(readPosition));
            minValueInBlock = min(minValueInBlock, currentValue);
        }
    }

    sharedMemory[index] = minValueInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {
        float4 minValue = sharedMemory[0];
        const auto threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            minValue = min(minValue, sharedMemory[i]);
        }
        result = minValue;
    }
}

#define outerArguments(T)                                          \
(texture2d<T, access::read> source [[ texture(0) ]],               \
constant BlockSize& inputBlockSize [[ buffer(0) ]],                \
device float4& result [[ buffer(1) ]],                             \
threadgroup float4* sharedMemory [[ threadgroup(0) ]],             \
const ushort index [[ thread_index_in_threadgroup ]],              \
const ushort2 position [[ thread_position_in_grid ]],              \
const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]]) \

#define innerArguments \
(source,               \
inputBlockSize,        \
result,                \
sharedMemory,          \
index,                 \
position,              \
threadsPerThreadgroup) \

generateKernels(textureMin)

#undef outerArguments
#undef innerArguments

// MARK: - Texture Mean

template <typename T>
void textureMean(texture2d<T, access::read> source,
                 constant BlockSize& inputBlockSize,
                 device float4& result,
                 threadgroup float4* sharedMemory,
                 const ushort index,
                 const ushort2 position,
                 const ushort2 threadsPerThreadgroup) {
    const auto textureSize = ushort2(source.get_width(),
                                     source.get_height());

    auto originalBlockSize = ushort2(inputBlockSize.width,
                                     inputBlockSize.height);
    const auto blockStartPosition = position * originalBlockSize;

    auto blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const auto readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - textureSize);
    }

    auto totalSumInBlock = float4(0);

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const auto readPosition = blockStartPosition + ushort2(x, y);
            const auto currentValue = float4(source.read(readPosition));
            totalSumInBlock += currentValue;
        }
    }

    sharedMemory[index] = totalSumInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {

        auto totalSum = sharedMemory[0];
        const auto threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
        for (ushort i = 1; i < threadsInThreadgroup; i++) {
            totalSum += sharedMemory[i];
        }

        auto gridSize = textureSize.x * textureSize.y;
        auto meanValue = totalSum / gridSize;

        result = meanValue;
    }
}

#define outerArguments(T)                                          \
(texture2d<T, access::read> source [[ texture(0) ]],               \
constant BlockSize& inputBlockSize [[ buffer(0) ]],                \
device float4& result [[ buffer(1) ]],                             \
threadgroup float4* sharedMemory [[ threadgroup(0) ]],             \
const ushort index [[ thread_index_in_threadgroup ]],              \
const ushort2 position [[ thread_position_in_grid ]],              \
const ushort2 threadsPerThreadgroup [[ threads_per_threadgroup ]]) \

#define innerArguments \
(source,               \
inputBlockSize,        \
result,                \
sharedMemory,          \
index,                 \
position,              \
threadsPerThreadgroup) \

generateKernels(textureMean)

#undef outerArguments
#undef innerArguments

// MARK: - Mask Guided Blur

kernel void maskGuidedBlurRowPass(texture2d<float, access::read> source [[ texture(0) ]],
                                  texture2d<float, access::sample> mask [[ texture(1) ]],
                                  texture2d<float, access::write> destination [[ texture(2) ]],
                                  constant float& sigma [[ buffer(0) ]],
                                  ushort2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(source.get_width(),
                                     source.get_height());

    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);

    const auto positionF = float2(position);
    const auto textureSizeF = float2(textureSize);
    const auto normalizedPosition = (positionF + 0.5f) / textureSizeF;

    const auto maskValue = mask.sample(s, normalizedPosition).r;

    const auto sigmaValue = (1.0f - maskValue) * sigma;
    const auto kernelRadius = int(2.0f * sigmaValue);

    auto normalizingConstant = 0.0f;
    auto result = float3(0.0f);

    for (int row = -kernelRadius; row <= kernelRadius; row++) {
        const auto kernelValue = exp(float(-row * row) / (2.0f * sigmaValue * sigmaValue + 1e-5f));
        const auto readPosition = uint2(clamp(position.x + row, 0, position.y - 1), position.y);
        const auto readPositionF = float2(readPosition);
        const auto normalizedPosition = (readPositionF.x + 0.5f) / textureSizeF;
        const auto maskMultiplier = 1.0f - mask.sample(s, normalizedPosition).r + 1e-5f;
        const auto totalFactor = kernelValue * maskMultiplier;
        normalizingConstant += float(totalFactor);
        result += source.read(readPosition).rgb * totalFactor;
    }

    result /= normalizingConstant;

    destination.write(float4(result, 1.0f), position);
}

kernel void maskGuidedBlurColumnPass(texture2d<float, access::read> source [[ texture(0) ]],
                                     texture2d<float, access::sample> mask [[ texture(1) ]],
                                     texture2d<float, access::write> destination [[ texture(2) ]],
                                     constant float& sigma [[ buffer(0) ]],
                                     uint2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(source.get_width(),
                                     source.get_height());

    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);

    const auto textureSizeF = float2(textureSize);
    const auto positionF = float2(position);
    const auto normalizedPosition = (positionF.x + 0.5f) / textureSizeF;

    const auto maskValue = mask.sample(s, normalizedPosition).r;

    const auto sigmaValue = (1.0f - maskValue) * sigma;
    const auto kernelRadius = uint(2.0f * sigmaValue);

    auto normalizingConstant = 0.0f;
    auto result = float3(0.0f);

    for (uint column = -kernelRadius; column <= kernelRadius; column++) {
        const auto kernelValue = exp(float(-column * column) / (2.0f * sigmaValue * sigmaValue + 1e-5f));
        const auto readPosition = uint2(position.x, clamp(position.y + column, 0u, position.y - 1));
        const auto readPositionF = float2(readPosition);
        const auto normalizedPosition = (readPositionF.x + 0.5f) / textureSizeF;
        const auto maskMultiplier = 1.0f - mask.sample(s, normalizedPosition).r + 1e-5f;
        const auto totalFactor = kernelValue * maskMultiplier;
        normalizingConstant += float(totalFactor);
        result += source.read(readPosition).rgb * totalFactor;
    }

    result /= normalizingConstant;

    destination.write(float4(result, 1.0f), position);
}

// MARK: - Euclidean Distance

template <typename T>
void euclideanDistance(texture2d<T, access::sample> textureOne,
                       texture2d<T, access::sample> textureTwo,
                       constant BlockSize& inputBlockSize,
                       device float& result,
                       threadgroup float* sharedMemory,
                       const ushort index,
                       const ushort2 position,
                       const ushort2 threadsPerThreadgroup) {
    const auto textureSize = ushort2(textureOne.get_width(),
                                     textureOne.get_height());

    auto originalBlockSize = ushort2(inputBlockSize.width,
                                     inputBlockSize.height);
    const auto blockStartPosition = position * originalBlockSize;

    auto blockSize = originalBlockSize;
    if (position.x == threadsPerThreadgroup.x || position.y == threadsPerThreadgroup.y) {
        const auto readTerritory = blockStartPosition + originalBlockSize;
        blockSize = originalBlockSize - (readTerritory - textureSize);
    }

    float euclideanDistanceSumInBlock = 0.0f;

    for (ushort x = 0; x < blockSize.x; x++) {
        for (ushort y = 0; y < blockSize.y; y++) {
            const auto readPosition = blockStartPosition + ushort2(x, y);
            const auto textureOneValue = float4(textureOne.read(readPosition));
            const auto textureTwoValue = float4(textureTwo.read(readPosition));
            euclideanDistanceSumInBlock += sqrt(dot(pow(textureOneValue - textureTwoValue, 2), 1));
        }
    }

    sharedMemory[index] = euclideanDistanceSumInBlock;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (index == 0) {
        auto totalEuclideanDistanceSum = sharedMemory[0];
        const auto threadsInThreadgroup = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
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
#undef euclidean


// MARK: - Add Constant

template <typename T>
void addConstant(texture2d<T, access::read> source,
                 texture2d<T, access::write> destination,
                 constant float4& constantValue,
                 const ushort2 position) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    auto sourceValue = source.read(position);
    auto destinationValue = sourceValue + vec<T, 4>(constantValue);
    destination.write(destinationValue, position);
}

#define outerArguments(T)                                 \
(texture2d<T, access::read> source [[ texture(0) ]],      \
texture2d<T, access::write> destination [[ texture(1) ]], \
constant float4& constantValue [[ buffer(0) ]],           \
const ushort2 position [[ thread_position_in_grid ]])

#define innerArguments \
(source,               \
destination,           \
constantValue,         \
position)

generateKernels(addConstant)

#undef outerArguments
#undef innerArguments

template <typename T>
void divideByConstant(texture2d<T, access::read> source,
                      texture2d<T, access::write> destination,
                      constant float4& constantValue,
                      const ushort2 position) {
    const auto textureSize = ushort2(source.get_width(),
                                     source.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    auto sourceValue = source.read(position);
    auto destinationValue = sourceValue / vec<T, 4>(constantValue);
    destination.write(destinationValue, position);
}

#define outerArguments(T)                                 \
(texture2d<T, access::read> source [[ texture(0) ]],      \
texture2d<T, access::write> destination [[ texture(1) ]], \
constant float4& constantValue [[ buffer(0) ]],           \
const ushort2 position [[ thread_position_in_grid ]])

#define innerArguments \
(source,               \
destination,           \
constantValue,         \
position)

generateKernels(divideByConstant)

#undef outerArguments
#undef innerArguments


// MARK: - Texture Mix

kernel void textureMaskedMix(texture2d<float, access::read> sourceOne [[ texture(0) ]],
                             texture2d<float, access::read> sourceTwo [[ texture(1) ]],
                             texture2d<float, access::sample> mask [[ texture(2) ]],
                             texture2d<float, access::write> destination [[ texture(3) ]],
                             const ushort2 position [[ thread_position_in_grid ]]) {
    const ushort2 textureSize = ushort2(destination.get_width(),
                                        destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);
    const auto positionF = float2(position);
    const auto textureSizeF = float2(textureSize);
    const auto normalizedPosition = (positionF + 0.5f) / textureSizeF;

    const auto sourceOneValue = sourceOne.read(position);
    const auto sourceTwoValue = sourceTwo.read(position);
    const auto maskValue = mask.sample(s, normalizedPosition).r;
    const auto resultValue = mix(sourceOneValue,
                                 sourceTwoValue,
                                 maskValue);
    destination.write(resultValue, position);
}

kernel void textureWeightedMix(texture2d<float, access::read> sourceOne [[ texture(0) ]],
                               texture2d<float, access::read> sourceTwo [[ texture(1) ]],
                               texture2d<float, access::write> destination [[ texture(2) ]],
                               constant float& weight [[ buffer(0) ]],
                               const ushort2 position [[ thread_position_in_grid ]]) {
    const ushort2 textureSize = ushort2(destination.get_width(),
                                        destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    const auto sourceOneValue = sourceOne.read(position);
    const auto sourceTwoValue = sourceTwo.read(position);
    const auto resultValue = mix(sourceOneValue,
                                 sourceTwoValue,
                                 weight);

    destination.write(resultValue, position);
}

// MARK: - Texture Multiply Add

kernel void textureMultiplyAdd(texture2d<float, access::read> sourceOne [[ texture(0) ]],
                               texture2d<float, access::read> sourceTwo [[ texture(1) ]],
                               texture2d<float, access::write> destination [[ texture(2) ]],
                               const ushort2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    const auto sourceOneValue = sourceOne.read(position);
    const auto sourceTwoValue = sourceTwo.read(position);
    const auto destinationValue = fma(sourceTwoValue,
                                      multiplierFC,
                                      sourceOneValue);
    destination.write(destinationValue,
                      position);
}

// MARK: - Texture Difference Hightlight

kernel void textureDifferenceHighlight(texture2d<float, access::read> sourceOne [[texture(0)]],
                                       texture2d<float, access::read> sourceTwo [[texture(1)]],
                                       texture2d<float, access::write> destination [[texture(2)]],
                                       constant float4& color [[ buffer(0) ]],
                                       constant float& threshold [[ buffer(1) ]],
                                       ushort2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    const auto originalColor = sourceOne.read(position);
    const auto targetColor = sourceTwo.read(position);
    const auto difference = abs(targetColor - originalColor);
    const auto totalDifference = dot(difference, 1.f);
    const auto resultValue = mix(targetColor,
                                 color,
                                 step(threshold, totalDifference));
    destination.write(resultValue, position);
}

// MARK: - ML

kernel void normalization(texture2d<half, access::read> inputTexture [[ texture(0) ]],
                          texture2d<half, access::write> outputTexture [[ texture(1) ]],
                          constant float3& mean [[ buffer(0) ]],
                          constant float3& std [[ buffer(1) ]],
                          uint2 position [[thread_position_in_grid]]) {
    const auto textureSize = ushort2(inputTexture.get_width(),
                                     inputTexture.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);
    
    // Read mpsnngraph result value.
    const auto originalValue = inputTexture.read(position);
    const auto meanValue = (half3)mean;
    const auto stdValue = (half3)std;
    auto normalizedValue = originalValue;
    normalizedValue.rgb -= meanValue;
    normalizedValue.rgb /= stdValue;
    outputTexture.write(normalizedValue, position);
}

// MARK: - Rendering

inline float2 perpendicular(float2 vector) {
    return float2(-vector.y, vector.x);
}

inline float2 convertToScreenSpace(float2 vector) {
    return float2(-1.0f + (vector.x * 2.0f),
                  -1.0f + ((1.0f - vector.y) * 2.0f));
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
    auto position = convertToScreenSpace(positions[vid]);
    out.position = float4(position, 0.0, 1.0);

    return out;
}

fragment float4 primitivesFragment(VertexOut in [[ stage_in ]],
                                   constant float4& color [[ buffer(0) ]]) {
    return color;
}


// MARK: - Texture Rendering

struct TextureFillVertexOut {
    float4 position [[ position ]];
    float2 uv;
};

vertex TextureFillVertexOut textureFillVertex(constant Rectangle& rectangle [[ buffer(0) ]],
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
    const auto position = convertToScreenSpace(vertices[vid].position);
    TextureFillVertexOut out = {
        .position = float4(position, 0.0, 1.0),
        .uv = vertices[vid].uv
    };

    return out;
}

fragment half4 textureFillFragment(TextureFillVertexOut in [[ stage_in ]],
                                   texture2d<half, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);

    return texture.sample(s, in.uv);
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
    const auto position = convertToScreenSpace(vertices[vid].position);
    MaskVertexOut out = {
        .position = float4(position, 0.0, 1.0),
        .uv = vertices[vid].uv
    };

    return out;
}

fragment float4 maskFragment(MaskVertexOut in [[ stage_in ]],
                             texture2d<float, access::sample> mask [[ texture(0) ]],
                             constant float4& color [[ buffer(0) ]],
                             constant bool& isInversed [[ buffer(1) ]]) {
    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);

    auto maskValue = mask.sample(s, in.uv).rrrr;
    if (isInversed) {
        maskValue = 1.0f - maskValue;
    }
    auto resultColor = maskValue * color;

    return resultColor;
}

// MARK: - Lines Rendering

vertex VertexOut linesVertex(constant Line *lines [[ buffer(0) ]],
                             uint vertexId [[ vertex_id ]],
                             uint instanceId [[ instance_id ]]) {
    Line line = lines[instanceId];

    auto startPoint = line.startPoint;
    auto endPoint = line.endPoint;

    auto vector = startPoint - endPoint;
    auto perpendicularVector = perpendicular(normalize(vector));
    auto halfWidth = line.width / 2.0f;

    struct PositionAndOffsetFactor {
        float2 vertexPosition;
        float offsetFactor;
    };

    const PositionAndOffsetFactor positionsAndOffsetFactors[] = {
        PositionAndOffsetFactor { startPoint, -1.0f },
        PositionAndOffsetFactor { endPoint, -1.0f },
        PositionAndOffsetFactor { startPoint, 1.0f },
        PositionAndOffsetFactor { endPoint, 1.0f }
    };

    const auto vertexPosition = positionsAndOffsetFactors[vertexId].vertexPosition;
    const auto offsetFactor = positionsAndOffsetFactors[vertexId].offsetFactor;
    const auto position = convertToScreenSpace(vertexPosition + offsetFactor * perpendicularVector * halfWidth);
    VertexOut out = { .position = float4(position, 0.0f, 1.0f) };

    return out;
}

// MARK: - Points Rendering

struct PointVertexOut {
    float4 position [[ position ]];
    float size [[ point_size ]];
};

vertex PointVertexOut pointVertex(constant float2* pointsPositions [[ buffer(0) ]],
                                  constant float& pointSize [[ buffer(1) ]],
                                  uint instanceId [[ instance_id ]]) {
    const auto pointPosition = pointsPositions[instanceId];

    const auto position = convertToScreenSpace(pointPosition);
    PointVertexOut out = {
        .position = float4(position, 0, 1),
        .size = pointSize
    };

    return out;
}

fragment float4 pointFragment(PointVertexOut in [[stage_in]],
                              const float2 pointCenter [[ point_coord ]],
                              constant float4& pointColor [[ buffer(0) ]]) {
    const auto distanceFromCenter = length(2 * (pointCenter - 0.5));

    auto color = pointColor;
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

// MARK: Look up table

kernel void lookUpTable(texture2d<float, access::read> source [[ texture(0) ]],
                        texture2d<float, access::write> destination [[ texture(1) ]],
                        texture3d<float, access::sample> lut [[ texture(2) ]],
                        constant float& intensity [[ buffer(0) ]],
                        uint2 position [[thread_position_in_grid]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);

    // read original color
    auto sourceValue = source.read(position);

    // use it to sample target color
    sourceValue.rgb = mix(sourceValue.rgb,
                          lut.sample(s, sourceValue.rgb).rgb,
                          intensity);

    // write it to destination texture
    destination.write(sourceValue, position);
}

// MARK: Texture affine crop

kernel void textureAffineCrop(texture2d<half, access::sample> source [[ texture(0) ]],
                              texture2d<half, access::write> destination [[ texture(1) ]],
                              constant float3x3& transform [[ buffer(0) ]],
                              ushort2 position [[thread_position_in_grid]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                        destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);
    const auto positionF = float2(position);
    const auto textureSizeF = float2(textureSize);
    const auto normalizedPosition = (positionF + 0.5f) / textureSizeF;

    const auto targetPosition = transform * float3(normalizedPosition, 1.0f);

    // read original color
    const auto sourceValue = source.sample(s, targetPosition.xy);

    // write it to destination texture
    destination.write(sourceValue, position);
}

// MARK: - Texture Interpolation

template <typename T>
void textureInterpolation(texture2d<T, access::read> sourceOne,
                          texture2d<T, access::read> sourceTwo,
                          texture2d<T, access::write> destination,
                          constant float& weight,
                          const ushort2 position) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    const auto sourceValueOne = sourceOne.read(position);
    const auto sourceValueTwo = sourceTwo.read(position);
    const auto resultValue = sourceValueOne + vec<T, 4>(float4(sourceValueTwo - sourceValueOne) * weight);

    destination.write(resultValue, position);
}

#define outerArguments(T)                                 \
(texture2d<T, access::read> sourceOne [[ texture(0) ]],   \
texture2d<T, access::read> sourceTwo [[ texture(1) ]],    \
texture2d<T, access::write> destination [[ texture(2) ]], \
constant float& weight [[ buffer(0) ]],                   \
const ushort2 position [[ thread_position_in_grid ]])     \

#define innerArguments \
(sourceOne,            \
sourceTwo,             \
destination,           \
weight,                \
position)              \

generateKernels(textureInterpolation)

#undef outerArguments
#undef innerArguments

// MARK: - YCbCr to RGBA

constant float4x4 ycbcrToRGBTransform = {
    { +1.0000f, +1.0000f, +1.0000f, +0.0000f },
    { +0.0000f, -0.3441f, +1.7720f, +0.0000f },
    { +1.4020f, -0.7141f, +0.0000f, +0.0000f },
    { -0.7010f, +0.5291f, -0.8860f, +1.0000f }
};

kernel void ycbcrToRGBA(texture2d<float, access::sample> sourceY [[ texture(0) ]],
                        texture2d<float, access::sample> sourceCbCr [[ texture(1) ]],
                        texture2d<float, access::write> destinationRGBA [[ texture(2) ]],
                        const ushort2 position [[ thread_position_in_grid ]],
                        const ushort2 totalThreads [[ threads_per_grid ]]) {
    const auto textureSize = ushort2(destinationRGBA.get_width(),
                                     destinationRGBA.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    constexpr sampler s(coord::normalized,
                        address::clamp_to_edge,
                        filter::linear);
    const auto positionF = float2(position);
    const auto textureSizeF = float2(textureSize);
    const auto normalizedPosition = (positionF + 0.5f) / textureSizeF;

    const auto ycbcr = float4(sourceY.sample(s, normalizedPosition).r,
                              sourceCbCr.sample(s, normalizedPosition).rg,
                              1.0f);
    const auto destinationValue = ycbcrToRGBTransform * ycbcr;

    destinationRGBA.write(destinationValue, position);
}

// MARK: - RGBA to YCbCr

constant float4x4 rgbaToYCbCrTransform = {
    { +0.2990f, -0.1687f, +0.5000f, +0.0000f },
    { +0.5870f, -0.3313f, -0.4187f, +0.0000f },
    { +0.1140f, +0.5000f, -0.0813f, +0.0000f },
    { -0.0000f, +0.5000f, +0.5000f, +1.0000f }
};

kernel void rgbaToYCbCr(texture2d<float, access::sample> sourceRGBA [[ texture(0) ]],
                        texture2d<float, access::write> destinationY [[ texture(1) ]],
                        texture2d<float, access::write> destinationCbCr [[ texture(2) ]],
                        const ushort2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(destinationCbCr.get_width(),
                                     destinationCbCr.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    if (halfSizedCbCr) {
        constexpr sampler s(coord::pixel,
                            address::clamp_to_edge,
                            filter::nearest);
        const auto positionF = float2(position);
        const auto gatherPosition = positionF * 2.0f + 1.0f;

        const auto rValuesForQuad = sourceRGBA.gather(s, gatherPosition,
                                                      0, component::x);
        const auto gValuesForQuad = sourceRGBA.gather(s, gatherPosition,
                                                      0, component::y);
        const auto bValuesForQuad = sourceRGBA.gather(s, gatherPosition,
                                                      0, component::z);
        const auto rgbaValues = transpose(float4x4(rValuesForQuad,
                                                   gValuesForQuad,
                                                   bValuesForQuad,
                                                   float4(1.0f)));
        const auto ycbcrValues = rgbaToYCbCrTransform * rgbaValues;

        destinationY.write(ycbcrValues[0].r, position * 2 + ushort2(0, 1));
        destinationY.write(ycbcrValues[1].r, position * 2 + ushort2(1, 1));
        destinationY.write(ycbcrValues[2].r, position * 2 + ushort2(1, 0));
        destinationY.write(ycbcrValues[3].r, position * 2 + ushort2(0, 0));

        const auto cbcrValue = (ycbcrValues * float4(0.25f)).gb;
        destinationCbCr.write(float4(cbcrValue, 0.0f), position);
    } else {
        const auto rgbaValue = sourceRGBA.read(position);
        const auto ycbcrValue = rgbaToYCbCrTransform * rgbaValue;
        const auto yValue = ycbcrValue.r;
        const auto cbcrValue = float4(ycbcrValue.gb, 0.0f);
        destinationY.write(yValue, position);
        destinationCbCr.write(cbcrValue, position);
    }
}

// MARK: - Bitonic Sort

#define SORT(F,L,R) {           \
    const auto v = sort(F,L,R); \
    (L) = v.x;                  \
    (R) = v.y;                  \
}                               \

inline static constexpr int genLeftIndex(const uint position,
                                         const uint blockSize) {
    const uint32_t blockMask = blockSize - 1;
    const auto no = position & blockMask; // comparator No. in block
    return ((position & ~blockMask) << 1) | no;
}

template <typename T>
inline static vec<T, 2> sort(const bool reverse,
                             T left,
                             T right) {
    const bool lt = left < right;
    const bool swap = !lt ^ reverse;
    const bool2 dir = bool2(swap, !swap); // (lt, gte) or (gte, lt)
    const vec<T, 2> v = select(vec<T, 2>(left),
                               vec<T, 2>(right),
                               dir);
    return v;
}

template <typename T>
inline static void loadShared(const uint threadGroupSize,
                              const uint indexInThreadgroup,
                              const uint position,
                              device T* data,
                              threadgroup T* shared) {
    const auto index = genLeftIndex(position, threadGroupSize);
    shared[indexInThreadgroup] = data[index];
    shared[indexInThreadgroup | threadGroupSize] = data[index | threadGroupSize];
}

template <typename T>
inline static void storeShared(const uint threadGroupSize,
                               const uint indexInThreadgroup,
                               const uint position,
                               device T* data,
                               threadgroup T* shared) {
    const auto index = genLeftIndex(position, threadGroupSize);
    data[index] = shared[indexInThreadgroup];
    data[index | threadGroupSize] = shared[indexInThreadgroup | threadGroupSize];
}

template <typename T>
void bitonicSortFirstPass(device T* data,
                          constant uint& gridSize,
                          threadgroup T* shared, // element num must be 2x (threads per threadgroup)
                          const uint threadgroupSize,
                          const uint indexInThreadgroup,
                          const uint position) {
    if (!deviceSupportsNonuniformThreadgroups && position >= gridSize) { return; }
    loadShared(threadgroupSize, indexInThreadgroup, position, data, shared);
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint unitSize = 1; unitSize <= threadgroupSize; unitSize <<= 1) {
        const bool reverse = (position & (unitSize)) != 0;    // to toggle direction
        for (uint blockSize = unitSize; 0 < blockSize; blockSize >>= 1) {
            const auto left = genLeftIndex(indexInThreadgroup, blockSize);
            SORT(reverse, shared[left], shared[left | blockSize]);
            threadgroup_barrier(mem_flags::mem_threadgroup);
        }
    }
    storeShared(threadgroupSize, indexInThreadgroup, position, data, shared);
}

#define outerArguments(T)                                         \
(device T* data [[ buffer(0) ]],                                  \
 constant uint& gridSize [[ buffer(1) ]],                         \
 threadgroup T* shared [[ threadgroup(0) ]],                      \
 const uint threadgroupSize [[ threads_per_threadgroup ]],        \
 const uint indexInThreadgroup [[ thread_index_in_threadgroup ]], \
 const uint position [[ thread_position_in_grid ]])

#define innerArguments \
(data,                 \
 gridSize,             \
 shared,               \
 threadgroupSize,      \
 indexInThreadgroup,   \
 position)

generateKernels(bitonicSortFirstPass)

#undef outerArguments
#undef innerArguments

template <typename T>
void bitonicSortGeneralPass(device T* data,         // should be multiple of params.x
                            constant uint& gridSize,
                            constant uint2& params, // x: monotonic width, y: comparative width
                            const uint position) {  // total threads should be half of data length
    if (!deviceSupportsNonuniformThreadgroups && position >= gridSize) { return; }
    const bool reverse = (position & (params.x >> 1)) != 0; // to toggle direction
    const uint blockSize = params.y; // size of comparison sets
    const auto left = genLeftIndex(position, blockSize);
    SORT(reverse, data[left], data[left | blockSize]);
}

#define outerArguments(T)                           \
(device T* data [[ buffer(0) ]],                    \
 constant uint& gridSize  [[ buffer(1) ]],          \
 constant uint2& params [[ buffer(2) ]],            \
 const uint position [[ thread_position_in_grid ]])

#define innerArguments \
(data,                 \
 gridSize,             \
 params,               \
 position)

generateKernels(bitonicSortGeneralPass)

#undef outerArguments
#undef innerArguments

template <typename T>
void bitonicSortFinalPass(device T* data,
                          constant uint& gridSize,
                          constant uint2& params,
                          threadgroup T* shared, // element num must be 2x (threads per threadgroup)
                          const uint threadgroupSize,
                          const uint indexInThreadgroup,
                          const uint position) {
    if (!deviceSupportsNonuniformThreadgroups && position >= gridSize) { return; }
    loadShared(threadgroupSize, indexInThreadgroup, position, data, shared);
    const auto unitSize = params.x;
    const auto blockSize = params.y;
    const auto num = 10 + 1;
    // Toggle direction.
    const bool reverse = (position & (unitSize >> 1)) != 0;
    for (uint i = 0; i < num; ++i) {
        const auto width = blockSize >> i;
        const auto left = genLeftIndex(indexInThreadgroup, width);
        SORT(reverse, shared[left], shared[left | width]);
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }
    storeShared(threadgroupSize, indexInThreadgroup, position, data, shared);
}

#define outerArguments(T)                                         \
(device T* data [[ buffer(0) ]],                                  \
 constant uint& gridSize [[ buffer(1) ]],                         \
 constant uint2& params [[ buffer(2) ]],                          \
 threadgroup T* shared [[ threadgroup(0) ]],                      \
 const uint threadgroupSize [[ threads_per_threadgroup ]],        \
 const uint indexInThreadgroup [[ thread_index_in_threadgroup ]], \
 const uint position [[ thread_position_in_grid ]])

#define innerArguments \
(data,                 \
 gridSize,             \
 params,               \
 shared,               \
 threadgroupSize,      \
 indexInThreadgroup,   \
 position)

generateKernels(bitonicSortFinalPass)

#undef outerArguments
#undef innerArguments
#undef SORT
