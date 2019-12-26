//
//  ViewController.swift
//  Demo
//
//  Created by Andrey Volodin on 02/12/2018.
//  Copyright © 2018 avolodin. All rights reserved.
//

import Cocoa
import Alloy
import AVFoundation
import SwiftMath

class ViewController: NSViewController {
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var slider: NSSlider!
    
    let context = try! MTLContext(device: Metal.lowPowerDevice!)
    var affineCropEncoder: TextureAffineCropEncoder!

    let image = NSImage(named: "flower")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = self.image
        
        self.affineCropEncoder = try! TextureAffineCropEncoder(context: self.context)
    }
    
    @IBAction func sliderDragged(_ sender: NSSlider) {
        var rect = NSRect(origin: .zero, size: self.image.size)
        // Very very bad and slow, just for demo purposes
        guard
            let cgImage = self.image.cgImage(forProposedRect: &rect,
                                             context: nil,
                                             hints: nil),
            let texture = try? context.texture(from: cgImage,
                                               usage: [.shaderRead, .shaderWrite])
        else { return }
        

        let cropTextureDescriptor = texture.descriptor
        cropTextureDescriptor.usage.insert(.shaderWrite)
        cropTextureDescriptor.width = 200
        cropTextureDescriptor.height = 100

        let transform = Matrix3x3f.translate(tx: 0.5, ty: 0.5)
                        * Matrix3x3f.rotate(angle: Angle(radians: sender.floatValue))
                        * Matrix3x3f.scale(sx: 1.9, sy: 0.2)
                        * Matrix3x3f.translate(tx: -0.5, ty: -0.5)

        let cropTexture = context.device.makeTexture(descriptor: cropTextureDescriptor)!

        try? self.context.scheduleAndWait { buffer in
            buffer.compute { encoder in
                self.affineCropEncoder.encode(sourceTexture: texture,
                                              destinationTexture: cropTexture,
                                              affineTransform: simd_float3x3(transform),
                                              using: encoder)
            }
            
            // For Mac applications (doesn't actually do anything, serves as an example)
            if case .managed = texture.storageMode {
                buffer.blit { encoder in
                    encoder.synchronize(resource: cropTexture)
                }
            }
        }
        
        self.imageView.image = try! cropTexture.image()
    }
}
