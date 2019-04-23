//
//  ShaderStructures.h
//  Alloy
//
//  Created by Eugene Bokhan on 23/04/2019.
//

#ifndef ShaderStructures_h
#define ShaderStructures_h

#include <simd/simd.h>

typedef struct Vertex {
    vector_float2 position;
} Vertex;

typedef struct RectVertices {
    Vertex topLeft;
    Vertex bottomLeft;
    Vertex topRight;
    Vertex bottomRight;
} RectVertices;

#endif /* ShaderStructures_h */
