//
//  ShaderStructures.h
//  Alloy
//
//  Created by Eugene Bokhan on 23/04/2019.
//

#ifndef ShaderStructures_h
#define ShaderStructures_h

#include <simd/simd.h>

typedef struct Rectangle {
    vector_float2 topLeft;
    vector_float2 bottomLeft;
    vector_float2 topRight;
    vector_float2 bottomRight;
} Rectangle;

typedef struct Line {
    vector_float2 startPoint;
    vector_float2 endPoint;
    float width;
} Line;

typedef struct BlockSize {
    ushort width;
    ushort height;
} BlockSize;

typedef struct CropRect {
    vector_int2 origin;
    vector_int2 size;
} CropRect;

#endif /* ShaderStructures_h */
