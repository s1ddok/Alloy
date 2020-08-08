#if !SwiftPM
import Foundation
private class BundleFinder {}
extension Foundation.Bundle {
    static var module = Bundle(for: BundleFinder.self)
}
#endif
