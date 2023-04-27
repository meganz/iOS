import Foundation
import MEGASdk

extension MEGAStringList {
    public func toArray() -> [String] {
        (0..<size).map { string(at: $0) }
    }
}
