import Foundation
#if !SWIFT_PM
public extension Bundle {
    static var module = Bundle(for: MTLContext.self)
}
#endif
public let bundle = Bundle.module
