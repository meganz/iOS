public extension Sequence {
    @inlinable func notContains(where predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        try !contains(where: predicate)
    }
}

public extension Sequence where Element: Equatable {
    @inlinable func notContains(_ element: Self.Element) -> Bool { !contains(element) }
}
