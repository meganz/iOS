import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

package protocol TransferControlRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Pauses a single in-flight transfer in the transfer engine.
    func pauseTransfer(_ transfer: TransferEntity) async throws
    /// Resumes a single paused transfer in the transfer engine.
    func resumeTransfer(_ transfer: TransferEntity) async throws
    /// Re-queues a finished (failed or cancelled) transfer. The SDK implements retry as
    /// creating a fresh transfer with the same parameters; the retried transfer runs on the Active tab.
    func retryTransfer(_ transfer: TransferEntity) async throws
    /// Cancels a single in-flight transfer in the transfer engine. The transfer finishes
    /// as Cancelled and moves to the completed-transfers cache (rendered by the Failed tab).
    func cancelTransfer(_ transfer: TransferEntity) async throws
    /// Re-queues the retryable transfers among the given tags: all downloads, and
    /// uploads whose staged source file still exists on disk. The caller scopes
    /// `tags` to the rows the Failed tab renders; the completed-transfers cache also
    /// holds transfers the tab hides (app-internal downloads, folder and streaming
    /// transfers), which must not be retried behind the user's back. State and
    /// retryability are re-checked here because the cache may have changed since
    /// the caller snapshotted it.
    /// - Returns: tags of the re-queued transfers, so the caller can clear their entries.
    func retryTransfers(tags: Set<Int>) -> Set<Int>
}

package enum TransferControlRepositoryError: Error {
    case transferNotFound
    case transferNotRetryable
}

package struct TransferControlRepository: TransferControlRepositoryProtocol {
    package static var newRepo: TransferControlRepository {
        TransferControlRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk
    private let fileManager: FileManager

    package init(sdk: MEGASdk, fileManager: FileManager = .default) {
        self.sdk = sdk
        self.fileManager = fileManager
    }

    package func pauseTransfer(_ transfer: TransferEntity) async throws {
        try await setTransfer(transfer, paused: true)
    }

    package func resumeTransfer(_ transfer: TransferEntity) async throws {
        try await setTransfer(transfer, paused: false)
    }

    package func retryTransfer(_ transfer: TransferEntity) async throws {
        guard let megaTransfer = completedMEGATransfer(for: transfer) else {
            throw TransferControlRepositoryError.transferNotFound
        }
        // Re-checked at action time: the row was rendered from an earlier snapshot
        // and the staged source file may have disappeared since.
        guard TransferRetryPolicy.isRetryable(
            megaTransfer.toTransferEntity(),
            sourceExists: fileManager.fileExists(atPath:)
        ) else {
            throw TransferControlRepositoryError.transferNotRetryable
        }
        sdk.retryTransfer(megaTransfer)
    }

    package func cancelTransfer(_ transfer: TransferEntity) async throws {
        try await withAsyncThrowingVoidValue { completion in
            sdk.cancelTransfer(byTag: transfer.tag, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }

    package func retryTransfers(tags: Set<Int>) -> Set<Int> {
        guard let completedTransfers = sdk.completedTransfers as? [MEGATransfer] else { return [] }
        let retryableTransfers = completedTransfers.filter { transfer in
            tags.contains(transfer.tag) && TransferRetryPolicy.isRetryable(
                transfer.toTransferEntity(),
                sourceExists: fileManager.fileExists(atPath:)
            )
        }
        retryableTransfers.forEach { sdk.retryTransfer($0) }
        return Set(retryableTransfers.map(\.tag))
    }

    /// Finished transfers are no longer addressable by tag in the transfer engine
    /// (`transferByTag:` only returns active transfers), so the original `MEGATransfer`
    /// must be recovered from the completed-transfers list, which retains failed and
    /// cancelled transfers.
    private func completedMEGATransfer(for transfer: TransferEntity) -> MEGATransfer? {
        (sdk.completedTransfers as? [MEGATransfer])?.first { $0.tag == transfer.tag }
    }

    /// Pause and resume share a single SDK entry point (`pauseTransferByTag:pause:`),
    /// addressing the transfer by its tag since the engine is keyed by tag, not handle.
    private func setTransfer(_ transfer: TransferEntity, paused: Bool) async throws {
        try await withAsyncThrowingVoidValue { completion in
            sdk.pauseTransfer(byTag: transfer.tag, pause: paused, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
}
