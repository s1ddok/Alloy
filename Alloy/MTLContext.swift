//
//  MTLContext.swift
//  Alloy
//
//  Created by Eugene Bokhan on 26.12.2019.
//

import Metal
import MetalKit

public final class MTLContext {

    // MARK: - Properties

    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue

    private var libraryCache: [Bundle: MTLLibrary] = [:]
    private lazy var textureLoader = MTKTextureLoader(device: self.device)

    // MARK: - Init

    public convenience init() throws {
        try self.init(device: Metal.device)
    }

    public init(commandQueue: MTLCommandQueue) {
        self.device = commandQueue.device
        self.commandQueue = commandQueue
    }

    public convenience init(device: MTLDevice,
                            bundle: Bundle = .main,
                            name: String? = nil) throws {
        guard let commandQueue = device.makeCommandQueue()
        else { fatalError("Could not create a command queue to form a Metal context") }

        let library: MTLLibrary?

        if name == nil {
            if #available(OSX 10.12, *) {
                library = try? device.makeDefaultLibrary(bundle: bundle)
            } else {
                library = device.makeDefaultLibrary()
            }
        } else {
            library = try device.makeLibrary(filepath: bundle.path(forResource: name!,
                                                                    ofType: "metallib")!)
        }

        self.init(commandQueue: commandQueue)
        self.libraryCache[bundle] = library
    }

    public func library(for class: AnyClass) throws -> MTLLibrary {
        return try self.library(for: Bundle(for: `class`))
    }

    public func library(for bundle: Bundle) throws -> MTLLibrary {
        if self.libraryCache[bundle] == nil {
            self.libraryCache[bundle] = try self.device
                                                .makeDefaultLibrary(bundle: bundle)
        }

        return self.libraryCache[bundle]!
    }

    public func purgeLibraryCache() {
        self.libraryCache = [:]
    }

    public func texture(from image: CGImage,
                        srgb: Bool? = nil,
                        usage: MTLTextureUsage = [.shaderRead],
                        generateMipmaps: Bool = false) throws -> MTLTexture {
        var options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: usage.rawValue),
            // You have to wrap everything inside NSNumber or it will be ignored
            .generateMipmaps: NSNumber(value: generateMipmaps)
        ]
        
        // This may look a bit messy but actually handles all cases:
        // 1. We let user ignore or pass .SRGB option
        // 2. If user ignored it we try to infer it from the image itself
        // 3. If image doesn't contain colorspace info and flag wasn't provided by user
        //    we simply don't pass anything and let MetalKit decide for us
        var isSRGB = srgb
        if isSRGB == nil, let colorSpace = image.colorSpace {
            isSRGB = colorSpace.name == CGColorSpace.sRGB
        }
        
        if let _isSRGB = isSRGB {
            options[.SRGB] = NSNumber(value: _isSRGB)
        }

        return try self.textureLoader
                       .newTexture(cgImage: image,
                                   options: options)
    }

}

