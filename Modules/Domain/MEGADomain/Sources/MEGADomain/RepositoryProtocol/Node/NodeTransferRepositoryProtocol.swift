import MEGASwift

public struct TransferResponseEntity: Sendable {
    public let transferEntity: TransferEntity
    public let error: ErrorEntity
    
    public var isSuccess: Bool {
        error.type == .ok
    }
    
    public init(transferEntity: TransferEntity, error: ErrorEntity) {
        self.transferEntity = transferEntity
        self.error = error
    }
}

public protocol NodeTransferRepositoryProtocol: RepositoryProtocol, Sendable {
    var transferStarUpdates: AnyAsyncSequence<TransferEntity> { get }
    var transferUpdates: AnyAsyncSequence<TransferEntity> { get }
    var transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> { get }
    var transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> { get }
}
