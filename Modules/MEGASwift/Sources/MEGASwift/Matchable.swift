import Foundation

infix operator ~~: ComparisonPrecedence
infix operator !~: ComparisonPrecedence

public protocol Matchable {
    static func ~~(lhs: Self, rhs: Self) -> Bool
}

public extension Matchable {
    static func !~(lhs: Self, rhs: Self) -> Bool {
        !(lhs ~~ rhs)
    }
}

extension Array: Matchable where Element: Matchable {
    public static func ~~ (lhs: Array<Element>, rhs: Array<Element>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy(~~)
    }
}

extension Optional: Matchable where Wrapped: Matchable {
    public static func ~~ (lhs: Optional<Wrapped>, rhs: Optional<Wrapped>) -> Bool {
        if lhs == nil && rhs == nil { return true }
        guard let lhs = lhs, let rhs = rhs else { return false }
        return lhs ~~ rhs
    }
}
