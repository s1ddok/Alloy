//
//  CommonErrors.swift
//  Alloy
//
//  Created by Andrey Volodin on 15/05/2019.
//

public enum MetalError: Error {
    public enum MTLCommandQueueError {
        case commandBufferCreationFailed
    }
    public enum MTLBufferError {
        case allocationFailed
    }
    public enum MTLLibraryError {
        case functionCreationFailed
    }
    public enum MTLTextureSerializationError {
        case unsupportedPixelFormat
        case dataAccessFailure
        case allocationFailed
    }
    public enum MTLDeviceError {
        case libraryCreationFailed
    }

    case commandQueue(MTLCommandQueueError)
    case buffer(MTLBufferError)
    case library(MTLLibraryError)
    case textureSerialization(MTLTextureSerializationError)
    case device(MTLDeviceError)
}
