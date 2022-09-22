import Foundation

extension Equatable {
    public func isEqual<T: Equatable>(_ rhs: T?) -> Bool {
        guard let rhs else { return false }
        guard let lhs = self as? T else { return false }
        return lhs == rhs
    }
}
