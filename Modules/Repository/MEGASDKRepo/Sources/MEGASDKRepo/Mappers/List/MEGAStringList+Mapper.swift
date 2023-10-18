import Foundation
import MEGASdk

extension MEGAStringList {
    public func toArray() -> [String] {
        (0..<size).compactMap { string(at: $0) }
    }
}
