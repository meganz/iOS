import MEGADomain
import MEGASwift

public struct MockTransfersListenerRepository: TransfersListenerRepositoryProtocol {
    private let (stream, continuation) = AsyncStream.makeStream(of: TransferEntity.self, bufferingPolicy: .bufferingNewest(1))
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public static var newRepo: MockTransfersListenerRepository {
        MockTransfersListenerRepository()
    }
    
    public func simulateTransfer(_ transfer: TransferEntity) {
        continuation.yield(transfer)
    }
    
    public init() {}
}
