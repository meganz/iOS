import FileProvider
import MEGADomain

extension TransferErrorEntity {
    /// What a transfer of the File Provider extension that finished with this error throws.
    /// - Parameters:
    ///   - isOverQuota: Whether the transfer was cancelled for being over quota, which it then fails with instead.
    ///   - isBusinessExpired: Whether the account is an expired business account once the transfer finished. The SDK
    ///     fails all its transfers, which `TransferDelegate` reports as plain upload or download errors; they become
    ///     `NSFileProviderError(.cannotSynchronize)`, so that the system stops retrying until the item changes.
    func toFileProviderError(isOverQuota: Bool, isBusinessExpired: Bool) -> any Error {
        switch self {
        case .cancelled:
            isOverQuota ? TransferErrorEntity.overquota : self
        default:
            isBusinessExpired ? NSFileProviderError(.cannotSynchronize) : self
        }
    }
}
