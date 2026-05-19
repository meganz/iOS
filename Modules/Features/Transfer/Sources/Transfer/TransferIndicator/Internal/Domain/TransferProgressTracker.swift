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

actor TransferProgressTracker {
    private var activeTransfers: [Int: TransferEntity] = [:]
    private var finishedTags: Set<Int> = []
    private var completedBytes: Int = 0
    private var totalBytes: Int = 0
    private var hasError = false
    private var hasOverquota = false
    private var hasCompleted = false
    private var hadTransfers = false
    private var isInitialized = false
    private var completedFileCount: Int = 0
    private var totalFileCount: Int = 0

    /// Seeds the tracker once from the current transfer inventory so monitoring starts
    /// from the same baseline as existing in-flight transfer work.
    func initializeIfNeeded(with transfers: [TransferEntity]) {
        guard !isInitialized else { return }
        isInitialized = true
        let filtered = transfers
            .filter { !$0.isFinished && !$0.isStreamingTransfer && !$0.isFolderTransfer }
        activeTransfers = Dictionary(uniqueKeysWithValues: filtered.map { ($0.tag, $0) })
        totalBytes = filtered.reduce(0) { $0 + max($1.totalBytes, 0) }
        completedBytes = filtered.reduce(0) { partialResult, transfer in
            partialResult + min(max(transfer.transferredBytes, 0), max(transfer.totalBytes, 0))
        }
        hadTransfers = !filtered.isEmpty
        totalFileCount = filtered.count
    }

    /// Clears the terminal outcome and cumulative byte counters for the current batch.
    ///
    /// This is called only after the terminal state has been consumed, so the next batch
    /// can start from a clean baseline without old completed/error state leaking through.
    func clearTerminalState() {
        hasError = false
        hasOverquota = false
        hasCompleted = false
        finishedTags.removeAll()
        completedBytes = 0
        totalBytes = 0
        hadTransfers = false
        completedFileCount = 0
        totalFileCount = 0
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
    func trackFinish(_ transfer: TransferEntity) {
        finishedTags.insert(transfer.tag)

        if let existingTransfer = activeTransfers[transfer.tag] {
            completedBytes += max(progressContribution(for: transfer) - progressContribution(for: existingTransfer), 0)
        } else {
            completedBytes += progressContribution(for: transfer)
        }

        if transfer.state == .complete {
            hasCompleted = true
            completedFileCount += 1
            return
        }

        if transfer.state == .cancelled || transfer.state == .failed {
            completedBytes = max(0, completedBytes - progressContribution(for: transfer))
            totalBytes = max(0, totalBytes - max(transfer.totalBytes, 0))
            // Cancellation reflects user intent ("don't count this"), so it's removed
            // from the total. Failure stays in the total so the visible gap is explained
            // by the error status icon ("0 of 1" reads as "the 1 thing I tried, failed").
            if transfer.state == .cancelled {
                totalFileCount = max(0, totalFileCount - 1)
            }
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

    /// Inserts or updates an active transfer inside the current batch and keeps the
    /// cumulative progress counters aligned with the latest transferred bytes.
    func upsert(_ transfer: TransferEntity) {
        guard !transfer.isFinished, !transfer.isStreamingTransfer, !transfer.isFolderTransfer,
              !finishedTags.contains(transfer.tag) else {
            activeTransfers.removeValue(forKey: transfer.tag)
            return
        }

        if let existingTransfer = activeTransfers[transfer.tag] {
            completedBytes += max(progressContribution(for: transfer) - progressContribution(for: existingTransfer), 0)
        } else {
            totalBytes += max(transfer.totalBytes, 0)
            completedBytes += progressContribution(for: transfer)
            totalFileCount += 1
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
    /// gone, the tracker resolves to the last batch outcome unless completed should be
    /// suppressed because more uploads are still queued to start.
    func snapshot(isGloballyPaused: Bool, hasPendingUploads: Bool) -> TransferStatusSnapshot? {
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
                if hasPendingUploads {
                    return TransferStatusSnapshot(
                        progress: 1,
                        hasError: false,
                        hasOverquota: false,
                        isPaused: false,
                        isCompleted: false,
                        activeUploadCount: 0,
                        activeDownloadCount: 0,
                        completedFileCount: completedFileCount,
                        totalFileCount: totalFileCount,
                        speedBytesPerSecond: 0
                    )
                }
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

    /// Calculates cumulative batch progress using total bytes and completed bytes
    /// across the whole batch, matching the legacy transfer circular widget.
    private func calculateProgress() -> CGFloat {
        guard totalBytes > 0 else { return 0 }

        let progress = CGFloat(completedBytes) / CGFloat(totalBytes)
        return min(max(progress, 0), 1)
    }

    private func progressContribution(for transfer: TransferEntity) -> Int {
        min(max(transfer.transferredBytes, 0), max(transfer.totalBytes, 0))
    }
}
