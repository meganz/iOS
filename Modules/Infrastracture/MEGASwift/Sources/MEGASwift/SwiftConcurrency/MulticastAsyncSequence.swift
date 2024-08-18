import Foundation

/// MulticastAsyncSequence provides a mechanism to manage and distribute  Elements to multiple AsyncSequences.
/// When a new value is yielded, it will distribute this Element to all active streams.
/// When an AsyncSequence is cancelled, it will cooperatively remove it from its list of managed AsyncSequences and no longer receive anymore yielded values.
/// The MulticastAsyncSequence will not cancel all managed streams via cooperatively cancellation, you will need to call `terminateContinuations` to end all active streams, before end a Task.
public actor MulticastAsyncSequence<Element: Sendable> {
        
    /// A strategy that handles exhaustion of a buffer’s capacity.
    public enum BufferingPolicy: Sendable {
        
        /// Continue to add to the buffer, without imposing a limit on the number
        /// of buffered elements.
        case unbounded
        
        /// When the buffer is full, discard the newly received element.
        ///
        /// This strategy enforces keeping at most the specified number of oldest
        /// values.
        case bufferingOldest(Int)
        
        /// When the buffer is full, discard the oldest element in the buffer.
        ///
        /// This strategy enforces keeping at most the specified number of newest
        /// values.
        case bufferingNewest(Int)
    }
    
    private var managedContinuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    
    public init() { }
    
    /// Create an AsyncSequence that will receive newly yielded values. And will be added to the list of managed sequences.
    /// If the sequence is called it will cooperatively remove it from the list of managed sequences.
    /// - Parameter bufferingPolicy: A strategy that handles exhaustion of a buffer’s capacity.
    /// - Returns: AnyAsyncSequence<Element>
    public func make(bufferingPolicy: BufferingPolicy = .bufferingNewest(1)) -> AnyAsyncSequence<Element> {
        let (stream, continuation) = AsyncStream
            .makeStream(of: Element.self, bufferingPolicy: bufferingPolicy.toAsyncStreamBufferingPolicy())
        
        let uuid = addContinuation(continuation: continuation)
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { [weak self] in await self?.terminateContinuation(id: uuid) }
        }
        
        return stream.eraseToAnyAsyncSequence()
    }
    
    /// Resume the task awaiting the next iteration point by having it return
    /// normally from its suspension point with a given element.
    public func yield(element: Element) {
        for continuation in managedContinuations.values {
            continuation.yield(element)
        }
    }
    
    /// Resume all managed task awaiting the next iteration point by having it return
    /// nil, which signifies the end of the iteration.
    public func terminateContinuations() {
        for continuation in managedContinuations.values {
            continuation.finish()
        }
    }
    
    private func addContinuation(id: UUID = UUID(), continuation: AsyncStream<Element>.Continuation) -> UUID {
        managedContinuations[id] = continuation
        return id
    }
    
    private func terminateContinuation(id: UUID) {
        managedContinuations[id] = nil
    }
}

fileprivate extension MulticastAsyncSequence.BufferingPolicy {
    func toAsyncStreamBufferingPolicy<T>() -> AsyncStream<T>.Continuation.BufferingPolicy {
        switch self {
        case .unbounded:
            .unbounded
        case .bufferingOldest(let count):
            .bufferingOldest(count)
        case .bufferingNewest(let count):
            .bufferingNewest(count)
        }
    }
}
