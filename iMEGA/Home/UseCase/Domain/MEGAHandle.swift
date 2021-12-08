import Foundation

typealias MEGABase64Handle = String

typealias MEGAHandle = UInt64

extension MEGAHandle {
    static let invalid = ~UInt64.zero
}
