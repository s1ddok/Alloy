# Alloy

Alloy is a tiny set of utils and extensions over Apple's Metal framework dedicated to make your Swift GPU code much cleaner and let you prototype your pipelines faster.

While this library doesn't introduce any new paradigms or concepts that significantly change the way you approach your Metal implementations, it has some optional-to-use things that you can incorporate in your apps if you find them as useful as library author did :)

- Nano-tiny layer over vanilla Metal API
- No external dependencies
- Cross-platform support
- Very Swifty

# Usage examples:

[Combine the power of CoreGraphics and Metal by sharing resource memory](https://medium.com/@s1ddok/combine-the-power-of-coregraphics-and-metal-by-sharing-resource-memory-eabb4c1be615)

# Okay, let me see what's up

First of all, this framework provides a set of utils, that hides the majority of redudant explicity in your Metal code, while not limiting a flexibility a bit. You can easily mix Alloy and vanilla Metal code.

The only new concept that Alloy introduces is `MTLContext`. Internally this is meant to store objects that are usually being shared and injected across your app.

In particular, this is:
- device: `MTLDevice`
- commandQueue: `MTLCommandQueue`
- standardLibrary: `MTLLibrary?`

Internally, it also manages a `MTKTextureLoader` and a cache of `MTLLibraries`, but this logic should be considered private. As of now, `MTLContext` **is not threadsafe**.

`MTLContext` usually being injected as a dependency to any object that interacts with Metal devices.

It can do a bunch of things for you, few examples:

### Easily create textures from CGImage
```swift
let texture = context.texture(from: cgImage,
                              usage: [.shaderRead, .shaderWrite])
```

### Dispatch command buffers in both sync/async manner

See how you can group encodings with Swift closures.

```swift
self.context.scheduleAndWait { buffer in
    buffer.compute { encoder in
      // compute command encoding logic
    }

    buffer.blit { encoder in
      // blit command encoding logic
    }
}
```

### Load a compute pipeline state for a function that sits in a framework
```swift
let lib = context.shaderLibrary(for: Foo.self)
let computePipelineState = try? lib.computePipelineState(function: "brightness")
```

### Allocate buffer by value type

```swift
let buffer = context.buffer(for: InstanceUniforms.self,
                            count: 99,
                            options: .storageModeShared)
```

### Serialize and deserialize MTLTexture 

```swift
let encoder = JSONEncoder()
let data = try encoder.encode(texture.codable())

let decoder = JSONDecoder()
let decodableTexture = try decoder.decode(MTLTextureCodableBox.self, from: data)
let decodedTexture = try decodableTexture.texture(device: self.context.device)
```

### Other things
- Create multi-sample render target pairs
- Create textures
- Create depth buffers
- Create depth/stencil states
- etc

## Other Alloy-specific types

Other types that are introduced by Alloy are

- `MTLOffscreenRenderer`: this is a class that lets you create simple off-screen renderers to draw something into arbitary `MTLTextures`
- `ComputeCommand`: this is an *experimental class* that does a reflection over Metal kernels and lets you assign arguments by name instead of index. This is a subject for improvements.
- `BlendingMode`: this type contains the enumeration of eight Alloy's built-in blending modes. You can easily setup one of them just by calling `setup(blending:)` function.
  ```swift
  let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
  renderPipelineDescriptor.colorAttachments[0].setup(blending: .alpha)
  ```

## MTLContext minimal usage example

`MTLContext` is usually being injected in the class, as you usually do with `MTLDevice`, you should cache the context and all heavy-weighted objects so you can reuse them lates, i.e.:

```swift
import Alloy

public class BrightnessEncoder {
    public let context: MTLContext
    fileprivate let pipelineState: MTLComputePipelineState

    /**
     * This variable controls the brightness factor. Should be in range of -1.0...1.0
     */
    public var intensity: Float = 1.0

    public init(context: MTLContext) {
        self.context = context

        guard let lib = context.shaderLibrary(for: BrightnessEncoder.self),
              let state = try? lib.computePipelineState(function: "brightness")
        else { fatalError("Error during shader loading") }

        self.pipelineState = state
    }

    public func encode(input: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.set(textures: [input])
            encoder.set(self.intensity, at: 0)

            encoder.dispatch2d(state: self.pipelineState,
                               covering: input.size)
        }
    }

}
```

Note how simple it is to kick off a kernel with Alloy, no more tedious thredgroup size calculations, multiple encoder initialization with balancing `.endEncoding()` calls.

Then somewhere else you just do

```swift
context.scheduleAndWait { buffer in
    self.brightnessEncoder.intensity = sender.floatValue
    self.brightnessEncoder.encode(input: texture,
                                  in: buffer)

    // For Mac applications
    if case .managed = texture.storageMode {
        buffer.blit { encoder in
            encoder.synchronize(resource: texture)
        }
    }
}
```

With this approach you can easily stack and build your GPU pipeline layers, group `blit`, `compute` and `render` command encodings with Swift closures, while maintaing full flexibility of Metal API.

# Installation

## CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Alloy into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
# Optionally add version, i.e. '~> 0.9.0'
pod 'Alloy'
```

License
----

MIT
