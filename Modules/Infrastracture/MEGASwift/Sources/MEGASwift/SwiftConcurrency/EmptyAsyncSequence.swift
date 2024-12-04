import Foundation

/// An async sequence that emits no items.
public struct EmptyAsyncSequence<Element>: AsyncSequence {
    public init() { }
    
    public struct Iterator: AsyncIteratorProtocol {
        mutating public func next() async -> Element? {
             nil
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator()
    }
}

extension EmptyAsyncSequence: Sendable where Element: Sendable { }
extension EmptyAsyncSequence.Iterator: Sendable where Element: Sendable { }
