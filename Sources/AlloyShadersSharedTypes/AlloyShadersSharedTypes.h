#ifndef AlloyShadersSharedTypes_h
#define AlloyShadersSharedTypes_h

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

#endif /* AlloyShadersSharedTypes_h */
