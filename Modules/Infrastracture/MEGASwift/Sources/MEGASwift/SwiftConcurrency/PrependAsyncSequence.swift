import Foundation

public extension AsyncSequence {
    /// Prefixes a async sequence output with the specified value.
    ///
    /// - Parameter element: element to yield prior to the async sequence
    func prepend(_ element: Element) -> PrependAsyncSequence<Self> where Element: Sendable {
        prepend { element }
    }
    
    /// Prefixes a async sequence output with the specified value.
    ///
    /// - Parameter element: async closure to yield prior to the async sequence
    func prepend(_ element: @Sendable @escaping () async -> Element) -> PrependAsyncSequence<Self> {
        PrependAsyncSequence(self, element: element)
    }
}

/// An async sequence that yield item before the base async sequence
public struct PrependAsyncSequence<Base: AsyncSequence>: AsyncSequence {
    public typealias Element = Base.Element
    
    private let base: Base
    private let element: @Sendable () async -> Element
    
    init(_ base: Base, element: @Sendable @escaping () async -> Element) {
        self.base = base
        self.element = element
      }
    
    public struct Iterator: AsyncIteratorProtocol {
        var iterator: Base.AsyncIterator
        var element: (@Sendable () async -> Element)?
        
        init(iterator: Base.AsyncIterator, element: @Sendable @escaping () async -> Element) {
            self.iterator = iterator
            self.element = element
        }
        
        public mutating func next() async rethrows -> Base.Element? {
            if let element {
                self.element = nil
                return await element()
            }
            return try await iterator.next()
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator(),
                 element: element)
    }
}

extension PrependAsyncSequence: Sendable where Base: Sendable, Base.Element: Sendable { }

@available(*, unavailable)
extension PrependAsyncSequence.Iterator: Sendable { }
