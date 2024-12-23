import Foundation
import MEGASwift

public protocol TransfersListenerUseCaseProtocol: Sendable {
    /// Async sequence of transfer objects
    /// Callers can listen to this sequence using a `for await ...` loop and can terminate the sequence by cancelling the containing concurrent task.
    var completedTransfers: AnyAsyncSequence<TransferEntity> { get }
    /// Pauses all queued transfers.
    /// Once paused, these transfers will not start until resumed.
    func pauseQueuedTransfers()
    /// Resumes the previously paused queued transfers.
    /// Once resumed, these transfers can start as normal.
    func resumeQueuedTransfers()
    /// Checks if queued transfers are currently paused.
    /// Returns `true` if they are paused, otherwise `false`.
    func areQueuedTransfersPaused() -> Bool
}

// MARK: - Use case implementation -
public struct TransfersListenerUseCase: TransfersListenerUseCaseProtocol {
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        repo.completedTransfers
    }
    
    private var repo: any TransfersListenerRepositoryProtocol
    
    @PreferenceWrapper(key: .queuedTransfersPaused, defaultValue: false)
    private var queuedTransfersPaused: Bool
    
    public init(
        repo: some TransfersListenerRepositoryProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol
    ) {
        self.repo = repo
        $queuedTransfersPaused.useCase = preferenceUseCase
    }
    
    public func pauseQueuedTransfers() {
        queuedTransfersPaused = true
    }
    
    public func resumeQueuedTransfers() {
        queuedTransfersPaused = false
    }
    
    public func areQueuedTransfersPaused() -> Bool {
        queuedTransfersPaused
    }
}
