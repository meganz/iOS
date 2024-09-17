import Combine
import MEGADomain
import MEGASwift

public struct MockTransfersListenerUseCase: TransfersListenerUseCaseProtocol {
    private let stream: AsyncStream<TransferEntity>
    private let continuation: AsyncStream<TransferEntity>.Continuation
    
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public init() {
        (stream, continuation) = AsyncStream
            .makeStream(of: TransferEntity.self)
    }
    
    public func simulateTransfer(_ transfer: TransferEntity) {
        continuation.yield(transfer)
    }
}
