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
/// `@unchecked Sendable`: the only stored member is a `PassthroughSubject`, whose
/// `send`/`subscribe` are documented thread-safe, so cross-actor sharing is sound.
package final class ClearTransfersUseCase: ClearTransfersUseCaseProtocol, @unchecked Sendable {
    private let repo: any ClearTransfersRepositoryProtocol
    private let clearedSubject = PassthroughSubject<Void, Never>()

    package init(repo: some ClearTransfersRepositoryProtocol) {
        self.repo = repo
    }

    package func clearCompletedTransfers() {
        repo.clearCompletedTransfers()
        clearedSubject.send()
    }

    package func clearFailedTransfers() {
        repo.clearFailedTransfers()
        clearedSubject.send()
    }

    package var clearedSignals: AnyAsyncSequence<Void> {
        clearedSubject.values.eraseToAnyAsyncSequence()
    }
}
