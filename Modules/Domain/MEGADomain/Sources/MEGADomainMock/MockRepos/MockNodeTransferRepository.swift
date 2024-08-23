import MEGADomain
import MEGASwift

public final class MockNodeTransferRepository: NodeTransferRepositoryProtocol {
    public static var newRepo: MockNodeTransferRepository {
        MockNodeTransferRepository()
    }
    
    private let stream: AsyncStream<TransferEntity>
    private let continuation: AsyncStream<TransferEntity>.Continuation
    
    public var nodeTransferCompletionUpdates: AnyAsyncSequence<TransferEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public init() {
        (stream, continuation) = AsyncStream<TransferEntity>.makeStream()
    }
    
    public func yield(_ transferEntity: TransferEntity) {
        continuation.yield(transferEntity)
    }
}
