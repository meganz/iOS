import Foundation

/// An async sequence that emits a single item.
public struct SingleItemAsyncSequence<Element>: AsyncSequence {
    private let item: Element
    
    public init(item: Element) {
        self.item = item
    }
    
    public struct SingleItemAsyncIterator: AsyncIteratorProtocol {
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
    
    public func makeAsyncIterator() -> SingleItemAsyncIterator {
        SingleItemAsyncIterator(item: item)
    }
}
