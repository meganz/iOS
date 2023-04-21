import Foundation

extension MEGAStringList {
    func toArray() -> [String] {
        (0..<size).map { string(at: $0) }
    }
}
