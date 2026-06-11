import MEGADomain
import MEGASdk

package protocol ClearTransfersRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Removes every successfully completed transfer from the completed-transfers cache.
    /// Failed and cancelled transfers are left untouched.
    func clearCompletedTransfers()
    /// Removes every failed or cancelled transfer from the completed-transfers cache.
    /// Successfully completed transfers are left untouched.
    func clearFailedTransfers()
}

package struct ClearTransfersRepository: ClearTransfersRepositoryProtocol {
    package static var newRepo: ClearTransfersRepository {
        ClearTransfersRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    package init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    package func clearCompletedTransfers() {
        removeCompletedTransfers { $0.state == .complete }
    }

    package func clearFailedTransfers() {
        removeCompletedTransfers { $0.state == .failed || $0.state == .cancelled }
    }

    /// Removes the matching entries from the app-maintained completed-transfers
    /// cache. The cache holds both completed and failed/cancelled transfers, so the
    /// predicate scopes the removal to the subset rendered by the calling tab.
    private func removeCompletedTransfers(matching predicate: (MEGATransfer) -> Bool) {
        guard let completedTransfers = sdk.completedTransfers as? [MEGATransfer] else { return }
        sdk.removeCompletedTransfers(completedTransfers.filter(predicate))
    }
}
