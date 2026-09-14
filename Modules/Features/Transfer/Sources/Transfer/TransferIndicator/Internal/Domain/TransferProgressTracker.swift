import CoreGraphics
import MEGADomain

struct TransferStatusSnapshot: Sendable, Equatable {
    let progress: CGFloat
    let hasError: Bool
    let hasOverquota: Bool
    let isPaused: Bool
    let isCompleted: Bool
    let activeUploadCount: Int
    let activeDownloadCount: Int
    let completedFileCount: Int
    let totalFileCount: Int
    let speedBytesPerSecond: Int64
}

/// Aggregates the current transfer batch into the snapshot that drives the in-app
/// indicator and the Live Activity.
///
/// Progress is derived, never accumulated — the same arithmetic a Transfer Manager row
/// does, summed over the batch: `sum(min(transferredBytes, totalBytes)) / sum(totalBytes)`.
/// The in-flight half is read from the entities on every snapshot so it follows the SDK
/// back down; only terminal transfers are reduced to running totals. The previous counter
/// used `completedBytes += max(delta, 0)`, which discarded those rewinds and drifted ahead.
actor TransferProgressTracker {
    private var activeTransfers: [Int: TransferEntity] = [:]
    /// Tags that already reached a terminal state, so a late update cannot resurrect one.
    private var finishedTags: Set<Int> = []
    /// What terminal transfers contribute, frozen at the moment they finished
    private var finishedBytes: Int = 0
    private var finishedTotalBytes: Int = 0
    private var finishedFileCount: Int = 0
    private var completedFileCount: Int = 0
    private var hasError = false
    private var hasOverquota = false
    private var hasCompleted = false
    private var hadTransfers = false
    private var isInitialized = false

    /// Seeds the tracker once from the current transfer inventory so monitoring starts
    /// from the same baseline as existing in-flight transfer work.
    func initializeIfNeeded(with transfers: [TransferEntity]) {
        guard !isInitialized else { return }
        isInitialized = true
        let filtered = transfers
            .filter { !$0.isFinished && !$0.isStreamingTransfer && !$0.isFolderTransfer }
        activeTransfers = Dictionary(uniqueKeysWithValues: filtered.map { ($0.tag, $0) })
        hadTransfers = !filtered.isEmpty
    }

    /// Clears the terminal outcome and drops the batch's transfers.
    ///
    /// This is called only after the terminal state has been consumed, so the next batch
    /// can start from a clean baseline without old completed/error state leaking through.
    func clearTerminalState() {
        hasError = false
        hasOverquota = false
        hasCompleted = false
        finishedTags.removeAll()
        finishedBytes = 0
        finishedTotalBytes = 0
        finishedFileCount = 0
        completedFileCount = 0
        hadTransfers = false
    }

    /// Records that a transfer has started as part of the current batch.
    ///
    /// Downloads clear any previous overquota flag once work resumes, matching the
    /// legacy widget behavior.
    func handleTransferStart(_ transfer: TransferEntity) {
        if transfer.type == .download, hasOverquota {
            hasOverquota = false
        }
        upsert(transfer)
    }

    func clearOverquota() {
        hasOverquota = false
    }

    func trackTemporaryError(_ response: TransferResponseEntity) {
        let errorType = response.error.type
        if errorType == .quotaExceeded || errorType == .notEnoughQuota {
            hasOverquota = true
        }
    }

    /// Records the terminal outcome of a finished transfer so the batch can later
    /// resolve to completed, warning, or error once no active transfers remain.
    ///
    /// This is where a transfer stops being read live and becomes a frozen contribution.
    /// It must run at most once per tag: unlike the in-flight side, these are running
    /// sums, so a repeated finish event would bank the same bytes twice.
    func trackFinish(_ transfer: TransferEntity) {
        guard !finishedTags.contains(transfer.tag) else { return }
        finishedTags.insert(transfer.tag)
        activeTransfers.removeValue(forKey: transfer.tag)

        switch transfer.state {
        case .cancelled:
            break
        case .failed:
            finishedFileCount += 1
        case .complete:
            hasCompleted = true
            finishedFileCount += 1
            completedFileCount += 1
            finishedBytes += progressContribution(for: transfer)
            finishedTotalBytes += max(transfer.totalBytes, 0)
        default:
            finishedFileCount += 1
            finishedBytes += progressContribution(for: transfer)
            finishedTotalBytes += max(transfer.totalBytes, 0)
        }

        guard transfer.state == .failed, let lastErrorExtended = transfer.lastErrorExtended else {
            return
        }

        switch lastErrorExtended {
        case .overquota:
            hasOverquota = true
        case .generic:
            break
        default:
            hasError = true
        }
    }

    /// Inserts or updates an active transfer inside the current batch.
    ///
    /// Storing the latest entity is the whole job — the totals are read back from it at
    /// snapshot time, so a transfer whose reported bytes went down drags the batch down
    /// with it, exactly like its Transfer Manager row does.
    func upsert(_ transfer: TransferEntity) {
        guard !transfer.isFinished, !transfer.isStreamingTransfer, !transfer.isFolderTransfer,
              !finishedTags.contains(transfer.tag) else {
            remove(tag: transfer.tag)
            return
        }

        activeTransfers[transfer.tag] = transfer
        hadTransfers = true
    }

    func remove(tag: Int) {
        activeTransfers.removeValue(forKey: tag)
    }

    /// Produces the aggregate snapshot for the current batch.
    ///
    /// Active transfers take priority over terminal rendering. Once active transfers are
    /// gone, the tracker resolves to the last batch outcome
    func snapshot(isGloballyPaused: Bool) -> TransferStatusSnapshot? {
        let transfers = Array(activeTransfers.values)

        guard !transfers.isEmpty || hasError || hasOverquota || hasCompleted else {
            return nil
        }

        if transfers.isEmpty {
            if hasError {
                return TransferStatusSnapshot(
                    progress: 1,
                    hasError: true,
                    hasOverquota: false,
                    isPaused: false,
                    isCompleted: false,
                    activeUploadCount: 0,
                    activeDownloadCount: 0,
                    completedFileCount: completedFileCount,
                    totalFileCount: totalFileCount,
                    speedBytesPerSecond: 0
                )
            } else if hasOverquota {
                return TransferStatusSnapshot(
                    progress: 1,
                    hasError: false,
                    hasOverquota: true,
                    isPaused: false,
                    isCompleted: false,
                    activeUploadCount: 0,
                    activeDownloadCount: 0,
                    completedFileCount: completedFileCount,
                    totalFileCount: totalFileCount,
                    speedBytesPerSecond: 0
                )
            } else if hasCompleted {
                return TransferStatusSnapshot(
                    progress: 1,
                    hasError: false,
                    hasOverquota: false,
                    isPaused: false,
                    isCompleted: true,
                    activeUploadCount: 0,
                    activeDownloadCount: 0,
                    completedFileCount: completedFileCount,
                    totalFileCount: totalFileCount,
                    speedBytesPerSecond: 0
                )
            } else {
                return nil
            }
        }

        let progress = calculateProgress()
        let activeUploadCount = transfers.filter { $0.type == .upload }.count
        let activeDownloadCount = transfers.filter { $0.type == .download }.count
        let aggregateSpeed = max(0, transfers.reduce(Int64(0)) { $0 + Int64($1.speed) })

        return TransferStatusSnapshot(
            progress: progress,
            hasError: hasError,
            hasOverquota: hasOverquota,
            isPaused: isGloballyPaused,
            isCompleted: false,
            activeUploadCount: activeUploadCount,
            activeDownloadCount: activeDownloadCount,
            completedFileCount: completedFileCount,
            totalFileCount: totalFileCount,
            speedBytesPerSecond: aggregateSpeed
        )
    }

    private var totalFileCount: Int {
        activeTransfers.count + finishedFileCount
    }

    /// The same arithmetic a Transfer Manager row does, summed over the batch:
    /// `Σ min(transferredBytes, totalBytes) / Σ totalBytes`
    private func calculateProgress() -> CGFloat {
        let active = activeTransfers.values
        let totalBytes = finishedTotalBytes + active.reduce(0) { $0 + max($1.totalBytes, 0) }
        guard totalBytes > 0 else { return 0 }

        let transferredBytes = finishedBytes + active.reduce(0) { $0 + progressContribution(for: $1) }
        return min(max(CGFloat(transferredBytes) / CGFloat(totalBytes), 0), 1)
    }

    private func progressContribution(for transfer: TransferEntity) -> Int {
        min(max(transfer.transferredBytes, 0), max(transfer.totalBytes, 0))
    }
}
