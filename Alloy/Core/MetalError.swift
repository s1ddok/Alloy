//
//  MetalError.swift
//  Alloy
//
//  Created by Andrey Volodin on 15/05/2019.
//

public enum MetalError {
    public enum MTLContextError: Error {
        case textureCacheCreationFailed
    }
    public enum MTLDeviceError: Error {
        case argumentEncoderCreationFailed
        case bufferCreationFailed
        case depthStencilStateCreationFailed
        case eventCreationFailed
        case fenceCreationFailed
        case heapCreationFailed
        case indirectCommandBufferCreationFailed
        case libraryCreationFailed
        case rasterizationRateMapCreationFailed
        case samplerStateCreationFailed
        case textureCreationFailed
        case textureViewCreationFailed
    }
    public enum MTLHeapError: Error {
        case bufferCreationFailed
        case textureCreationFailed
    }
    public enum MTLCommandQueueError: Error {
        case commandBufferCreationFailed
    }
    public enum MTLLibraryError: Error {
        case functionCreationFailed
    }
    public enum MTLTextureSerializationError: Error {
        case allocationFailed
        case dataAccessFailure
        case unsupportedPixelFormat
    }
    public enum MTLTextureError: Error {
        case imageCreationFailed
        case imageIncompatiblePixelFormat
    }
    public enum MTLBufferError: Error {
        case incompatibleData
    }
}
