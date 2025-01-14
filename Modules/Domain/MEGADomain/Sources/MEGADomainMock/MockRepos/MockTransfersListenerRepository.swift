import MEGADomain
import MEGASwift

public final class MockTransfersListenerRepository: TransfersListenerRepositoryProtocol, @unchecked Sendable {
    private let stream: AsyncStream<TransferEntity>
    private let continuation: AsyncStream<TransferEntity>.Continuation
    
    public var pauseTransfers_calledTimes = 0
    public var resumeTransfers_calledTimes = 0
    
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public static var newRepo: MockTransfersListenerRepository {
        MockTransfersListenerRepository()
    }
    
    public func simulateTransfer(_ transfer: TransferEntity) {
        continuation.yield(transfer)
    }
    
    public func simulateTransferCompletion() {
        continuation.finish()
    }
    
    public init() {
        (stream, continuation) = AsyncStream.makeStream(of: TransferEntity.self, bufferingPolicy: .unbounded)
    }
    
    public func pauseTransfers() {
        pauseTransfers_calledTimes += 1
    }
    
    public func resumeTransfers() {
        resumeTransfers_calledTimes += 1
    }
}
