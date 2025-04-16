import Metal

public extension MTLResource {

    var isAccessibleOnCPU: Bool {
        #if ((os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)) || os(tvOS)
        return self.storageMode == .shared
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        return self.storageMode == .managed || self.storageMode == .shared
        #endif
    }

}
