import Foundation

public extension AsyncSequence {
    /// Prefixes a async sequence output with the specified value.
    ///
    /// - Parameter item: item to yield prior to the async sequence
    func prepend(_ item: Element) -> PrependAsyncSequence<Self> {
        PrependAsyncSequence(self, item: item)
    }
}

/// An async sequence that yield item before the base async sequence
public struct PrependAsyncSequence<Base: AsyncSequence>: AsyncSequence {
    public typealias Element = Base.Element
    
    private let base: Base
    private let item: Element
    
    init(_ base: Base, item: Element) {
        self.base = base
        self.item = item
      }
    
    public struct PrependAsyncIterator: AsyncIteratorProtocol {
        var iterator: Base.AsyncIterator
        var item: Element?
        
        init(iterator: Base.AsyncIterator, itemToPrepend: Element) {
            self.iterator = iterator
            self.item = itemToPrepend
        }
        
        public mutating func next() async rethrows -> Base.Element? {
            if let item {
                self.item = nil
                return item
            }
            return try await iterator.next()
        }
    }
    
    public func makeAsyncIterator() -> PrependAsyncIterator {
        PrependAsyncIterator(iterator: base.makeAsyncIterator(),
                             itemToPrepend: item)
    }
}
