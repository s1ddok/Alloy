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
    public enum MTLCommandQueueError: Error {
        case commandBufferCreationFailed
    }
    public enum MTLBufferError: Error {
        case allocationFailed
    }
    public enum MTLLibraryError: Error {
        case functionCreationFailed
    }
    public enum MTLTextureSerializationError: Error {
        case unsupportedPixelFormat
        case dataAccessFailure
        case allocationFailed
    }
    public enum MTLTextureError: Error {
        case imageCreationFailed
        case imageIncompatiblePixelFormat
    }
    public enum MTLDeviceError: Error {
        case libraryCreationFailed
        case textureCreationFailed
        case textureViewCreationFailed
        case heapCreationFailed
        case bufferCreationFailed
        case depthStencilStateCreationFailed
    }
}
