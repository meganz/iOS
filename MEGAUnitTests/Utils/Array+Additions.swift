import Foundation

extension Array {
    mutating func removeFirstWithAssertion() -> Element {
        precondition(!isEmpty, "No elements to remove from an empty array")
        return removeFirst()
    }
}
