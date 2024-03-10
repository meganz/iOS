import Foundation

/// An async sequence that performs type erasure by wrapping another async sequence.
public struct AnyAsyncSequence<Element>: AsyncSequence, Sendable {
    private let generateIterator: @Sendable () -> Iterator
    
    public init<S>(_ sequence: S) where S: AsyncSequence, S.Element == Element, S: Sendable, S.Element: Sendable {
        generateIterator = { Iterator(sequence.makeAsyncIterator()) }
    }
    
    public func makeAsyncIterator() -> Iterator {
        generateIterator()
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: any AsyncIteratorProtocol
        
        public init<I>(_ iterator: I) where I: AsyncIteratorProtocol, I.Element == Element {
            self.iterator = iterator
        }
        
        mutating public func next() async -> Element? {
            // `try? await self.iterator.next() as? Element` is causing weird behaviour and it's not clear why.
            guard let element = try? await iterator.next() else {
                return nil
            }
            return element as? Element
        }
    }
}

@available(*, unavailable)
extension AnyAsyncSequence.Iterator: Sendable { }

/// An async throwing sequence that performs type erasure by wrapping another async sequence.
public struct AnyAsyncThrowingSequence<Element, Failure>: AsyncSequence, Sendable where Failure: Error {
    private let generateIterator: @Sendable () -> Iterator
    
    public init<S>(_ sequence: S) where S: AsyncSequence, S.Element == Element, Failure == Error, S: Sendable, S.Element: Sendable {
        generateIterator = { Iterator(sequence.makeAsyncIterator()) }
    }
    
    public func makeAsyncIterator() -> Iterator {
        generateIterator()
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: any AsyncIteratorProtocol
        
        public init<I>(_ iterator: I) where I: AsyncIteratorProtocol, I.Element == Element {
            self.iterator = iterator
        }
        
        mutating public func next() async throws -> Element? {
            // `try? await self.iterator.next() as? Element` caused issues in `AnyAsyncSequence.Iterator'. Adding the extra guard statement just to be safe.
            guard let element = try await iterator.next() else {
                return nil
            }
            return element as? Element
        }
    }
}

@available(*, unavailable)
extension AnyAsyncThrowingSequence.Iterator: Sendable { }
