import MEGADomain
import MEGASwift

public final class MockNodeTransferRepository: NodeTransferRepositoryProtocol {
    public static var newRepo: MockNodeTransferRepository {
        MockNodeTransferRepository()
    }

    public let transferStarUpdates: AnyAsyncSequence<TransferEntity>
    public let transferUpdates: AnyAsyncSequence<TransferEntity>
    public let transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity>
    public let transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity>

    public init(
        transferStarUpdates: AnyAsyncSequence<TransferEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        transferUpdates: AnyAsyncSequence<TransferEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.transferStarUpdates = transferStarUpdates
        self.transferUpdates = transferUpdates
        self.transferTemporaryErrorUpdates = transferTemporaryErrorUpdates
        self.transferFinishUpdates = transferFinishUpdates
    }
}
