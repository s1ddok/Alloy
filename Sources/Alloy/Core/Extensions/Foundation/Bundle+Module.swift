import Foundation
#if NEEDS_BUNDLE_MODULE_DEFINITION
public extension Bundle {
    static var module = Bundle(for: MTLContext.self)
}
#endif
public let bundle = Bundle.module
