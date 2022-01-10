import Foundation

infix operator ↻: ComparisonPrecedence
infix operator !↻: ComparisonPrecedence

protocol Refreshable {
    static func ↻(lhs: Self, rhs: Self) -> Bool
}

extension Refreshable {
    static func !↻(lhs: Self, rhs: Self) -> Bool {
        !(lhs ↻ rhs)
    }
}
