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

    public func library(for class: AnyClass) -> MTLLibrary? {
        return self.library(for: Bundle(for: `class`))
    }

    public func library(for bundle: Bundle) -> MTLLibrary? {
        if let cachedLibrary = self.libraryCache[bundle] {
            return cachedLibrary
        }

        guard let library = try? self.device
                                     .makeDefaultLibrary(bundle: bundle)
        else { return nil }

        self.libraryCache[bundle] = library
        return library
    }

    public func purgeLibraryCache() {
        self.libraryCache = [:]
    }

    public func texture(from image: CGImage,
                        srgb: Bool = false,
                        usage: MTLTextureUsage = [.shaderRead],
                        generateMipmaps: Bool = false) throws -> MTLTexture {
        let options: [MTKTextureLoader.Option: Any] = [
            // Note: the SRGB option should be set to false, otherwise the image
            // appears way too dark, since it wasn't actually saved as SRGB.
            .SRGB : srgb, // image.colorSpace == CGColorSpace(name: CGColorSpace.sRGB)
            .textureUsage: NSNumber(value: usage.rawValue),
            .generateMipmaps: generateMipmaps
        ]

        return try self.textureLoader
                       .newTexture(cgImage: image,
                                   options: options)
    }

}

