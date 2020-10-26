import Cocoa
import Alloy
import AVFoundation
import SwiftMath

class ViewController: NSViewController {
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var slider: NSSlider!
    
    let context = try! MTLContext()
    var affineCropEncoder: TextureAffineCrop!

    let image = NSImage(named: "flower")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = self.image
        
        self.affineCropEncoder = try! TextureAffineCrop(context: self.context)
    }
    
    @IBAction func sliderDragged(_ sender: NSSlider) {
        var rect = NSRect(origin: .zero, size: self.image.size)
        
        do {
            let cgImage = self.image.cgImage(forProposedRect: &rect,
                                             context: nil,
                                             hints: nil)!
            let texture = try context.texture(from: cgImage,
                                              srgb: false,
                                              usage: [.shaderRead, .shaderWrite])
            let cropTexture = try texture.matchingTexture()
            
            let transform = Matrix3x3f.translate(tx: 0.5, ty: 0.5)
                          * Matrix3x3f.rotate(angle: Angle(radians: sender.floatValue))
                          * Matrix3x3f.translate(tx: -0.5, ty: -0.5)
            
            try self.context.scheduleAndWait { buffer in
                self.affineCropEncoder(source: texture,
                                       destination: cropTexture,
                                       affineTransform: simd_float3x3(transform),
                                       in: buffer)
                
                // For Mac applications (doesn't actually do anything, serves as an example)
                if case .managed = texture.storageMode {
                    buffer.blit { encoder in
                        encoder.synchronize(resource: cropTexture)
                    }
                }
            }
            
            self.imageView.image = try cropTexture.image()
        } catch { return }
    }
}
