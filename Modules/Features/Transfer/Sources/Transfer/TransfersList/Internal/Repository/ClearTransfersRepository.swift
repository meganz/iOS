import MEGADomain
import MEGASdk

package protocol ClearTransfersRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Removes every successfully completed transfer from the completed-transfers cache.
    /// Failed and cancelled transfers are left untouched.
    /// - Returns: tags removed from the SDK completed-transfers cache.
    func clearCompletedTransfers() -> Set<Int>
    /// Removes every failed or cancelled transfer from the completed-transfers cache.
    /// Successfully completed transfers are left untouched.
    /// - Returns: tags removed from the SDK completed-transfers cache.
    func clearFailedTransfers() -> Set<Int>
    /// Removes the single completed/failed transfer with the given tag.
    /// - Returns: tags removed from the SDK completed-transfers cache (empty if no match).
    func clearTransfer(tag: Int) -> Set<Int>
}

package struct ClearTransfersRepository: ClearTransfersRepositoryProtocol {
    package static var newRepo: ClearTransfersRepository {
        ClearTransfersRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    package init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    package func clearCompletedTransfers() -> Set<Int> {
        removeCompletedTransfers { $0.state == .complete }
    }

    package func clearFailedTransfers() -> Set<Int> {
        removeCompletedTransfers { $0.state == .failed || $0.state == .cancelled }
    }

    package func clearTransfer(tag: Int) -> Set<Int> {
        removeCompletedTransfers { $0.tag == tag }
    }

    /// Removes the matching entries from the app-maintained completed-transfers
    /// cache. The cache holds both completed and failed/cancelled transfers, so the
    /// predicate scopes the removal to the subset rendered by the calling tab.
    private func removeCompletedTransfers(matching predicate: (MEGATransfer) -> Bool) -> Set<Int> {
        guard let completedTransfers = sdk.completedTransfers as? [MEGATransfer] else { return [] }

        let transfersToRemove = completedTransfers.filter(predicate)
        sdk.removeCompletedTransfers(transfersToRemove)
        return Set(transfersToRemove.map(\.tag))
    }
}
