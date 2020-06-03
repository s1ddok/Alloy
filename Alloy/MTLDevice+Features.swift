import Metal

public enum Feature {
    case nonUniformThreadgroups
}

public extension MTLDevice {
    func supports(feature: Feature) -> Bool {
        switch feature {
        case .nonUniformThreadgroups:
            #if targetEnvironment(macCatalyst)
            return self.supportsFamily(.common3)
            #elseif os(iOS)
            return self.supportsFeatureSet(.iOS_GPUFamily4_v1)
            #elseif os(macOS)
            return self.supportsFeatureSet(.macOS_GPUFamily1_v3)
            #endif
        }
    }
}
