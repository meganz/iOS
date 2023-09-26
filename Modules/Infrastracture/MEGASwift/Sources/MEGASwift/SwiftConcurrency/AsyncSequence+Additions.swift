import Foundation

public extension AsyncSequence {
    
    /// Wraps this async sequence with a type eraser.
    ///
    /// Use ``eraseToAnyAsyncThrowingSequence`` to get an ``AnyAsyncThrowingSequence`` if your async sequence throws an error.
    ///
    /// - Returns: An ``AnyAsyncSequence`` wrapping this async sequence with the same associated Element.
    func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(self)
    }
    
    /// Wraps this async sequence with a type eraser.
    ///
    /// Use ``eraseToAnyAsyncSequence`` to get an ``AnyAsyncSequence`` if your async sequence does not throw an error.
    ///
    /// - Returns: An ``AnyAsyncThrowingSequence`` wrapping this async sequence with the same associated Element.
    func eraseToAnyAsyncThrowingSequence() -> AnyAsyncThrowingSequence<Element, Error> {
        AnyAsyncThrowingSequence(self)
    }
}
