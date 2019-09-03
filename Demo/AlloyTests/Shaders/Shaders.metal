kernel void switchDataFormat(texture2d<float, access::read_write> normalizedTexture [[ texture(0) ]],
                             texture2d<uint, access::read_write> unnormalizedTexture [[ texture(1) ]],
                             const ushort2 position [[thread_position_in_grid]]) {
    const ushort2 textureSize = ushort2(normalizedTexture.get_width(),
                                        normalizedTexture.get_height());
    checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups);

    if (conversionTypeDenormalize) {
        float4 floatValue = normalizedTexture.read(position);
        uint4 intValue = uint4(floatValue * 255);
        unnormalizedTexture.write(intValue, position);
    } else {
        uint4 intValue = unnormalizedTexture.read(position);
        float4 floatValue = float4(intValue) / 255;
        normalizedTexture.write(floatValue, position);
    }
}
