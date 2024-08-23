import MEGADomain
import MEGASDKRepo
import MEGASwift

public final class MockNodeTransferCompletionUpdatesProvider: NodeTransferCompletionUpdatesProviderProtocol {
    private let stream: AsyncStream<TransferEntity>
    private let continuation: AsyncStream<TransferEntity>.Continuation
    
    public var nodeTransferUpdates: AnyAsyncSequence<TransferEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public init() {
        (stream, continuation) = AsyncStream<TransferEntity>.makeStream()
    }
    
    public func yield(_ transferEntity: TransferEntity) {
        continuation.yield(transferEntity)
    }
}
