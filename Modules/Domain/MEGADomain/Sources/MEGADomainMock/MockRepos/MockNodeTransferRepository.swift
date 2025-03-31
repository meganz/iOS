import MEGADomain
import MEGASwift

public final class MockNodeTransferRepository: NodeTransferRepositoryProtocol {
    public static var newRepo: MockNodeTransferRepository {
        MockNodeTransferRepository()
    }

    public let transferFinishUpdates: AnyAsyncSequence<Result<TransferEntity, ErrorEntity>>

    public init(
        transferFinishUpdates: AnyAsyncSequence<Result<TransferEntity, ErrorEntity>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.transferFinishUpdates = transferFinishUpdates
    }
}
