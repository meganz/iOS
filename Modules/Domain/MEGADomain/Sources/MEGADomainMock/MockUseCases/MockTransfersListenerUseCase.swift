import Combine
import MEGADomain
import MEGASwift

public final class MockTransfersListenerUseCase: TransfersListenerUseCaseProtocol, @unchecked Sendable {
    private let stream: AsyncStream<TransferEntity>
    private let continuation: AsyncStream<TransferEntity>.Continuation
    private let paused: Bool
    
    public var pauseQueuedTransfersCalledTimes = 0
    public var resumeQueuedTransfersCalledTimes = 0
    
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public init(paused: Bool = false) {
        (stream, continuation) = AsyncStream
            .makeStream(of: TransferEntity.self)
        self.paused = paused
    }
    
    public func simulateTransfer(_ transfer: TransferEntity) {
        continuation.yield(transfer)
    }
    
    public func pauseQueuedTransfers() {
        pauseQueuedTransfersCalledTimes += 1
    }
    
    public func resumeQueuedTransfers() {
        resumeQueuedTransfersCalledTimes += 1
    }
    
    public func areQueuedTransfersPaused() -> Bool {
        paused
    }
}
