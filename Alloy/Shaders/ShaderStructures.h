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
    packed_float2 topLeft;
    packed_float2 bottomLeft;
    packed_float2 topRight;
    packed_float2 bottomRight;
} Rectangle;

typedef struct Line {
    packed_float2 startPoint;
    packed_float2 endPoint;
    float width;
} Line;

#endif /* ShaderStructures_h */
