//
//  MetalError.swift
//  Alloy
//
//  Created by Andrey Volodin on 15/05/2019.
//

public enum MetalError {
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
    public enum MTLDeviceError: Error {
        case libraryCreationFailed
        case samplerStateCreationFailed
    }
}
