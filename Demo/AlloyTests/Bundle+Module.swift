#if !SWIFT_PM
import Foundation
public extension Bundle {
    static var module = Bundle(for: AlloyTests.self)
}
#endif
