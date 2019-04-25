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
    vector_float4 fillColor;
} Rectangle;

typedef struct Line {
    vector_float2 startPoint;
    vector_float2 endPoint;
    float width;
    vector_float4 fillColor;
} Line;

#endif /* ShaderStructures_h */
