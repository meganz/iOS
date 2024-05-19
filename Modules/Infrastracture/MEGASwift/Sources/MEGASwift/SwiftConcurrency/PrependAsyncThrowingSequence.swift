import Foundation

public extension AsyncSequence {
    /// Prefixes a async sequence output with the specified value.
    ///
    /// - Parameter element: async closure to yield prior to the async sequence. If the closure throws an error, the sequence throws.
    func prepend(_ element: @Sendable @escaping () async throws -> Element) -> PrependAsyncThrowingSequence<Self> {
        PrependAsyncThrowingSequence(self, element: element)
    }
}

/// An async sequence that yield element that can throw before the base async sequence ending the sequence
public struct PrependAsyncThrowingSequence<Base: AsyncSequence>: AsyncSequence {
    public typealias Element = Base.Element
    
    private let base: Base
    private let element: @Sendable () async throws -> Element
    
    init(_ base: Base, element: @Sendable @escaping () async throws -> Element) {
        self.base = base
        self.element = element
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        var iterator: Base.AsyncIterator
        var element: (@Sendable () async throws -> Element)?
        
        init(iterator: Base.AsyncIterator, element: @Sendable @escaping () async throws -> Element) {
            self.iterator = iterator
            self.element = element
        }
        
        public mutating func next() async throws -> Base.Element? {
            if let element {
                self.element = nil
                return try await element()
            }
            return try await iterator.next()
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator(),
                 element: element)
    }
}

extension PrependAsyncThrowingSequence: Sendable where Base: Sendable, Base.Element: Sendable { }

@available(*, unavailable)
extension PrependAsyncThrowingSequence.Iterator: Sendable { }
