infix operator ↻↻: ComparisonPrecedence
infix operator !↻: ComparisonPrecedence

infix operator ↻↻⏿: ComparisonPrecedence
infix operator !↻⏿: ComparisonPrecedence

public protocol Refreshable {
    static func ↻↻ (lhs: Self, rhs: Self) -> Bool
}

public extension Refreshable {
    static func !↻ (lhs: Self, rhs: Self) -> Bool {
        !(lhs ↻↻ rhs)
    }
}

public protocol RefreshableWhenVisible {
    static func ↻↻⏿ (lhs: Self, rhs: Self) -> Bool
}

public extension RefreshableWhenVisible {
    static func !↻⏿ (lhs: Self, rhs: Self) -> Bool {
        !(lhs ↻↻⏿ rhs)
    }
}
