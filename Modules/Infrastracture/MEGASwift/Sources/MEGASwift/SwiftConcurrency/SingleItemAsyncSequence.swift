import Foundation

/// An async sequence that emits a single item.
public struct SingleItemAsyncSequence<Element>: AsyncSequence {
    private let item: Element
    
    public init(item: Element) {
        self.item = item
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var item: Element?
        
        init(item: Element) {
            self.item = item
        }
        
        mutating public func next() async -> Element? {
            guard let item else {
                return nil
            }
            self.item = nil
            return item
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(item: item)
    }
}

extension SingleItemAsyncSequence: Sendable where Element: Sendable { }
extension SingleItemAsyncSequence.Iterator: Sendable where Element: Sendable { }
