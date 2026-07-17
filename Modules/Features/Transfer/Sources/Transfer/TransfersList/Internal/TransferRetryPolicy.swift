import Foundation
import MEGADomain

/// Single source of truth for transfer retryability.
///
/// Downloads always retry (the source is the cloud node). Uploads retry only
/// while their staged source file still exists — temporary sources are unlinked
/// by the SDK on any finish, and retrying without the file can only fail again.
/// Non-terminal transfers are never retryable.
package enum TransferRetryPolicy {
    package static func isRetryable(
        _ entity: TransferEntity,
        sourceExists: (String) -> Bool
    ) -> Bool {
        guard entity.state == .failed || entity.state == .cancelled else { return false }
        guard entity.type == .upload else { return true }
        guard let path = entity.path, !path.isEmpty else { return false }
        return sourceExists(path)
    }
}
