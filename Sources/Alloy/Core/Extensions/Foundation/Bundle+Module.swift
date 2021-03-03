import Foundation
#if !SWIFT_PACKAGE
public extension Bundle {
    static var module = Bundle(for: MTLContext.self)
}
#endif
public let bundle = Bundle.module
