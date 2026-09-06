import MEGASwift

// MARK: - Use case protocol -
public protocol CancellableTransferUseCaseProtocol: Sendable {
    /// Starts every transfer in the batch, emitting folder progress along the way and exactly one
    /// terminal state, after which the sequence finishes.
    ///
    /// Asking for the sequence is what starts the batch, as the name says: it does not wait to be
    /// read, so a caller that drops the sequence has still handed its transfers over. Dropping it
    /// only stops the states being reported.
    func start(transfers: [CancellableTransferEntity]) -> AnyAsyncSequence<CancellableTransferStateEntity>
    
    /// Cancels the transfers started by this instance.
    func cancel()
}
