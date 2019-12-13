//
//  MetalError.swift
//  Alloy
//
//  Created by Andrey Volodin on 15/05/2019.
//

public enum MetalError {
    public enum MTLHeapError: Error {
        case textureCreationFailed
        case bufferCreationFailed
    }
    public enum MTLDeviceError: Error {
        case libraryCreationFailed
        case bufferCreationFailed
        case samplerStateCreationFailed
        case textureCreationFailed
    }
    public enum MTLCommandQueueError: Error {
        case commandBufferCreationFailed
    }
    public enum MTLLibraryError: Error {
        case functionCreationFailed
    }
    public enum MTLTextureSerializationError: Error {
        case unsupportedPixelFormat
        case dataAccessFailure
        case allocationFailed
    }
}
