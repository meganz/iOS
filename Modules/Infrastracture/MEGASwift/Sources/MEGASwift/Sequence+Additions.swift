public extension Sequence {
    @inlinable func notContains(where predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        try !contains(where: predicate)
    }
}
