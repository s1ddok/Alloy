import MetalPerformanceShaders

public class GlobalPoolPadding: NSObject, MPSNNPadding {

    public override init() {}

    // MARK: MPSNNPadding

    public func paddingMethod() -> MPSNNPaddingMethod {
        return .custom
    }

    public func label() -> String {
        return "PyTorch Global Pool Padding rule"
    }

    public func destinationImageDescriptor(forSourceImages sourceImages: [MPSImage],
                                           sourceStates: [MPSState]?,
                                           for kernel: MPSKernel,
                                           suggestedDescriptor inDescriptor: MPSImageDescriptor) -> MPSImageDescriptor {
        inDescriptor.width = 1
        inDescriptor.height = 1

        return inDescriptor
    }

    // MARK: NSCoding

    public static var supportsSecureCoding: Bool {
        return false
    }

    public func encode(with aCoder: NSCoder) {
        fatalError("NSCoding is not supported yet")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding is not supported yet")
    }

}
