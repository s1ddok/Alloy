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

class ViewController: NSViewController {
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var slider: NSSlider!
    
    let context = MTLContext(device: Metal.lowPowerDevice!)
    var brightnessEncoder: BrightnessEncoder!

    let image = NSImage(named: "flower")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = self.image
        
        self.brightnessEncoder = BrightnessEncoder(context: self.context)
    }
    
    @IBAction func sliderDragged(_ sender: NSSlider) {
        var rect = NSRect(origin: .zero, size: self.image.size)
        // Very very bad and slow, just for demo purposes
        guard
            let cgImage = self.image.cgImage(forProposedRect: &rect,
                                             context: nil,
                                             hints: nil),
            let texture = context.texture(from: cgImage,
                                          usage: [.shaderRead, .shaderWrite])
        else { return }

        self.context.scheduleAndWait { buffer in
            self.brightnessEncoder.intensity = sender.floatValue
            self.brightnessEncoder.encode(input: texture,
                                          in: buffer)
            
            // For Mac applications (doesn't actually do anything, serves as an example)
            if case .managed = texture.storageMode {
                buffer.blit { encoder in
                    encoder.synchronize(resource: texture)
                }
            }
        }
        
        self.imageView.image = texture.image
    }
}
