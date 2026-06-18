import Combine
import MEGASwift

// MARK: - Use case protocol -
package protocol ClearTransfersUseCaseProtocol: Sendable {
    /// Clears the list of successfully completed transfers shown on the Completed tab.
    func clearCompletedTransfers()
    /// Clears the list of failed and cancelled transfers shown on the Failed tab.
    func clearFailedTransfers()
    /// Emits once each time a clear runs. Clearing is a silent SDK cache removal that
    /// fires no transfer delegate event, so the mounted tab observes this to re-query
    /// the now-changed cache. Multicast: the emitter outlives the tabs, while each tab
    /// that mounts subscribes and drops its subscription when it unmounts.
    var clearedSignals: AnyAsyncSequence<Void> { get }
}

// MARK: - Use case implementation -
/// `@unchecked Sendable`: injected collaborators are Sendable, and the
/// `PassthroughSubject` is used only for thread-safe `send`/`subscribe` bridging
/// into `clearedSignals`.
package final class ClearTransfersUseCase: ClearTransfersUseCaseProtocol, @unchecked Sendable {
    private let repo: any ClearTransfersRepositoryProtocol
    private let finishDateProvider: (any TransferFinishDateProviding)?
    private let clearedSubject = PassthroughSubject<Void, Never>()

    package init(
        repo: some ClearTransfersRepositoryProtocol,
        finishDateProvider: (any TransferFinishDateProviding)? = nil
    ) {
        self.repo = repo
        self.finishDateProvider = finishDateProvider
    }

    package func clearCompletedTransfers() {
        let removedTags = repo.clearCompletedTransfers()
        finishDateProvider?.removeDates(forTags: removedTags)
        clearedSubject.send()
    }

    package func clearFailedTransfers() {
        let removedTags = repo.clearFailedTransfers()
        finishDateProvider?.removeDates(forTags: removedTags)
        clearedSubject.send()
    }

    package var clearedSignals: AnyAsyncSequence<Void> {
        clearedSubject.values.eraseToAnyAsyncSequence()
    }
}
