import Foundation

/// An async sequence that emits emits no items.
public struct EmptyAsyncSequence<Element>: AsyncSequence {
    public init() { }
    
    public struct EmptyItemAsyncIterator: AsyncIteratorProtocol {
        mutating public func next() async -> Element? {
             nil
        }
    }
    
    public func makeAsyncIterator() -> EmptyItemAsyncIterator {
        EmptyItemAsyncIterator()
    }
}
