//
//  Definitions.h
//  AlloyTests
//
//  Created by Eugene Bokhan on 03/09/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

#ifndef Definitions_h
#define Definitions_h

// MARK: - Generate Template Kernels

#define generateKernel(functionName, scalarType, outerArgs, innerArgs) \
kernel void functionName##_##scalarType outerArgs {                    \
        functionName innerArgs;                                        \
}

#define generateKernels(functionName)                                        \
generateKernel(functionName, float, outerArguments(float), innerArguments);  \
generateKernel(functionName, half, outerArguments(half), innerArguments);    \
generateKernel(functionName, int, outerArguments(int), innerArguments);      \
generateKernel(functionName, short, outerArguments(short), innerArguments);  \
generateKernel(functionName, uint, outerArguments(uint), innerArguments);    \
generateKernel(functionName, ushort, outerArguments(ushort), innerArguments);

// MARK: - Check Position

#define checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups) \
if (!deviceSupportsNonuniformThreadgroups) {                                       \
    if (position.x >= textureSize.x || position.y >= textureSize.y) {              \
        return;                                                                    \
    }                                                                              \
}

#endif /* Definitions_h */
