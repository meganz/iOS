import Combine
import MEGADomain
import MEGASwift

public struct MockTransfersListenerUseCase: TransfersListenerUseCaseProtocol {
    let (stream, continuation) = AsyncStream
        .makeStream(of: TransferEntity.self)
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public init() {}
    
    public func simulateTransfer(_ transfer: TransferEntity) {
        continuation.yield(transfer)
    }
}
