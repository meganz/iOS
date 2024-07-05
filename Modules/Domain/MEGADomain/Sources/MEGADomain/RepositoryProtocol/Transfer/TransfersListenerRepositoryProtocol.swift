import MEGASwift

public protocol TransfersListenerRepositoryProtocol: RepositoryProtocol, Sendable {
    var completedTransfers: AnyAsyncSequence<TransferEntity> { get }
}
