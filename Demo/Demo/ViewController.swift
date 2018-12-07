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

    var computePipelineState: MTLComputePipelineState! = nil

    let image = NSImage(named: "flower")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = self.image
        
        guard let lib = context.standardLibrary,
              let computePipelineState = try? lib.computePipelineState(function: "brightness")
        else {
            fatalError("Metal initialization step failed")
        }
        
        self.computePipelineState = computePipelineState
    }
    
    @IBAction func sliderDragged(_ sender: NSSlider) {
        var rect = NSRect(origin: .zero, size: self.image.size)
        guard
            let cgImage = self.image.cgImage(forProposedRect: &rect,
                                             context: nil,
                                             hints: nil),
            let texture = context.texture(from: cgImage,
                                          usage: [.shaderRead, .shaderWrite])
        else { return }
        
        self.context.scheduleAndWait { buffer in
            buffer.compute { encoder in
                encoder.set(textures: [texture])
                encoder.set(sender.floatValue, at: 0)
                
                encoder.dispatch2d(state: self.computePipelineState,
                                   covering: texture.size)
            }
            
            buffer.blit { encoder in
                encoder.synchronize(resource: texture)
            }
        }
        
        self.imageView.image = texture.image
    }
}
