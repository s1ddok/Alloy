//
//  Metal.swift
//  Alloy
//
//  Created by Andrey Volodin on 13.05.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import Metal
import MetalKit

public final class Metal {
    
    public static let device: MTLDevice! = MTLCreateSystemDefaultDevice()
    
    #if os(macOS) || targetEnvironment(macCatalyst)
    @available(macCatalyst 13.0, *)
    public static let lowPowerDevice: MTLDevice? = {
        return MTLCopyAllDevices().first { $0.isLowPower }
    }()
    #endif // os(macOS) || targetEnvironment(macCatalyst)
    
    public static var isAvailable: Bool {
        return Metal.device != nil
    }
    
}
