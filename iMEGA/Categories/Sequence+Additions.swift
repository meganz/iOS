import Foundation

extension Sequence {
    @inlinable public func notContains(where predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        try !contains(where: predicate)
    }
}
