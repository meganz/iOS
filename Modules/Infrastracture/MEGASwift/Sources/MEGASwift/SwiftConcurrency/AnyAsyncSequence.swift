import Foundation

/// An async sequence that performs type erasure by wrapping another async sequence.
public struct AnyAsyncSequence<Element>: AsyncSequence {
    private let generateIterator: () -> Iterator
    
    public init<S>(_ sequence: S) where S: AsyncSequence, S.Element == Element {
        generateIterator = { Iterator(sequence.makeAsyncIterator()) }
    }
    
    public func makeAsyncIterator() -> Iterator {
        generateIterator()
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let generateNext: () async -> Element?
        
        mutating public func next() async -> Element? {
            await generateNext()
        }
        
        public init<I>(_ iterator: I) where I: AsyncIteratorProtocol, I.Element == Element {
            var iterator = iterator
            generateNext = { try? await iterator.next() }
        }
    }
}

/// An async throwing sequence that performs type erasure by wrapping another async sequence.
public struct AnyAsyncThrowingSequence<Element, Failure>: AsyncSequence where Failure: Error {
    private let generateIterator: () -> Iterator
    
    public init<S>(_ sequence: S) where S: AsyncSequence, S.Element == Element, Failure == Error {
        generateIterator = { Iterator(sequence.makeAsyncIterator()) }
    }
    
    public func makeAsyncIterator() -> Iterator {
        generateIterator()
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let generateNext: () async throws -> Element?
        
        mutating public func next() async throws -> Element? {
            try await generateNext()
        }
        
        public init<I>(_ iterator: I) where I: AsyncIteratorProtocol, I.Element == Element {
            var iterator = iterator
            generateNext = { try await iterator.next() }
        }
    }
}
