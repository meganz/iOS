import MEGADomain
import MEGASdk

/// Forwards the events of the files inside a download batch,
///
/// A file of a batch reaches globally registered delegates only, so this has to be added to the SDK
/// instead of being passed to `startDownloadBatch`. The batch's own tag is what tells this batch's files
/// apart from every other transfer the SDK reports; set it from the batch's start, which fires first.
final class BatchItemDownloadTransferDelegate: NSObject, MEGATransferDelegate, @unchecked Sendable {
    private let onEvent: @Sendable (Result<TransferEventEntity, TransferErrorEntity>) -> Void
    private var batchTag: Int?
    private let lock: NSLock = NSLock()

    init(onEvent: @Sendable @escaping (Result<TransferEventEntity, TransferErrorEntity>) -> Void) {
        self.onEvent = onEvent
    }

    func setBatchTag(_ tag: Int) {
        lock.withLock {
            guard batchTag == nil else { return }
            batchTag = tag
        }
    }

    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        guard isItemOfBatch(transfer) else { return }
        onEvent(.success(.start(transfer.toTransferEntity())))
    }

    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        guard isItemOfBatch(transfer) else { return }
        onEvent(.success(.update(transfer.toTransferEntity())))
    }

    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard isItemOfBatch(transfer) else { return }
        onEvent(.success(.temporaryError(transfer.toTransferEntity(), error.toErrorEntity())))
    }

    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard isItemOfBatch(transfer) else { return }

        guard error.type == .apiOk else {
            onEvent(.failure(transfer.state == .cancelled ? .cancelled : .download))
            return
        }

        onEvent(.success(.finish(transfer.toTransferEntity())))
    }

    private func isItemOfBatch(_ transfer: MEGATransfer) -> Bool {
        lock.withLock { !transfer.isFolderTransfer && transfer.folderTransferTag == batchTag }
    }
}
