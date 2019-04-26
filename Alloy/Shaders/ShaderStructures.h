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

typedef struct SimplePoint {
    vector_float2 position;
} SimplePoint;

#endif /* ShaderStructures_h */
