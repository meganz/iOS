import MEGADomain
import MEGASwift

/// Counts what a folder download actually brought down, out of the global stream of finished transfers.
///
/// The SDK reports a folder download to its caller as one transfer with one outcome, but fires a separate
/// finish callback for every file inside it, each pointing back at the folder through its
/// `folderTransferTag`. Those callbacks are the only place a file's individual fate is reported.
///
/// Sub transfers are tallied per folder tag rather than filtered against ours as they arrive, so it does
/// not matter whether the folder's own tag is known by the time the first of them lands.
///
/// Synchronised rather than isolated: every call arrives from an SDK callback, and the result is read from
/// the download that owns it once that download has been told it is over.
final class FolderDownloadProgress: @unchecked Sendable {
    @Atomic private var folderTransferTag: Int?
    /// What the tree building stage reported: the size the finished scan arrived at.
    @Atomic private var treeFileCount = 0
    /// What the transferring stage reported: how many sub transfers the SDK actually queued.
    @Atomic private var queuedFileCount: Int?
    @Atomic private var downloadedFileCountByFolderTag = [Int: Int]()

    func setFolderTransferTag(_ tag: Int) {
        $folderTransferTag.mutate { $0 = tag }
    }

    func noteFolderUpdate(_ update: FolderTransferUpdateEntity) {
        let fileCount = Int(update.fileCount)

        switch update.stage {
        case .transferringFiles:
            $queuedFileCount.mutate { $0 = fileCount }
        case .createTree:
            $treeFileCount.mutate { $0 = max($0, fileCount) }
        default:
            break
        }
    }

    /// - Parameter transfer: A sub transfer that finished successfully. Whether it succeeded is the
    ///   caller's to establish, since only what arrived is worth counting.
    func record(_ transfer: TransferEntity) {
        guard !transfer.isFolderTransfer, transfer.folderTransferTag > 0 else { return }

        $downloadedFileCountByFolderTag.mutate { $0[transfer.folderTransferTag, default: 0] += 1 }
    }

    /// - Parameter isSuccess: Whether the folder transfer itself finished without error.
    func result(isSuccess: Bool) -> FolderDownloadResultEntity {
        FolderDownloadResultEntity(
            isSuccess: isSuccess,
            fileCount: queuedFileCount ?? treeFileCount,
            downloadedFileCount: folderTransferTag.map { downloadedFileCountByFolderTag[$0] ?? 0 } ?? 0
        )
    }
}
