infix operator ↻↻: ComparisonPrecedence
infix operator !↻: ComparisonPrecedence

public protocol Refreshable {
    static func ↻↻(lhs: Self, rhs: Self) -> Bool
}

public extension Refreshable {
    static func !↻(lhs: Self, rhs: Self) -> Bool {
        !(lhs ↻↻ rhs)
    }
}
