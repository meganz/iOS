import MEGASwift

public protocol TransfersListenerRepositoryProtocol: RepositoryProtocol, Sendable {
    /// A sequence that asynchronously yields completed transfer entities.
    /// This property provides an `AnyAsyncSequence` of `TransferEntity` that asynchronously
    /// delivers completed transfers as they occur.
    var completedTransfers: AnyAsyncSequence<TransferEntity> { get }
    /// Pauses all ongoing transfers.
    /// When invoked, this method pause any transfers that are currently in progress.
    func pauseTransfers()
    /// Resumes all paused transfers.
    /// If any transfers were paused previously, this method resume those transfers.
    func resumeTransfers()
}
