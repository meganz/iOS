@testable import MEGA
import Testing

/// Validates the predicate that `deletePendingRecordsBeforeDate:` uses to pick stale records on
/// "Upload Only New Photos" toggle ON. Evaluating the predicate against sample records keeps this
/// deterministic and free of CoreData / PhotoKit: the only logic worth testing is which (status,
/// creationDate) combinations are selected for deletion.
///
/// Note: the cleanup deliberately does NOT resolve PHAssets to check whether the underlying asset
/// still exists — under `.limited` photo permission a by-identifier lookup cannot see non-selected
/// assets and would wrongly delete still-present records. So there is no "asset gone" case here;
/// reconciliation is driven purely by the stored `creationDate` vs the cutoff, with a missing
/// `creationDate` treated as pre-cutoff (it cannot satisfy the scan-time `creationDate >= cutoff`
/// filter either).
struct CameraUploadRecordCleanupTests {
    private let cutoff = Date(timeIntervalSinceReferenceDate: 1_000_000)

    private func selectsForDeletion(status: CameraAssetUploadStatus, creationOffset: Double?) -> Bool {
        let predicate = CameraUploadRecordManager.pendingRecordsToDeletePredicate(before: cutoff)
        var record: [String: Any] = ["status": NSNumber(value: status.rawValue)]
        if let creationOffset {
            record["creationDate"] = cutoff.addingTimeInterval(creationOffset)
        }
        return predicate.evaluate(with: record)
    }

    // Pending records are removed when their stored capture date is before the cutoff, or when
    // they have no stored `creationDate` at all (treated as pre-cutoff — not an "asset gone" check).
    @Test(arguments: [
        CameraAssetUploadStatus.notStarted,
        .notReady,
        .cancelled,
        .failed,
        .unknown
    ])
    func pendingPreCutoffRecordsAreDeleted(status: CameraAssetUploadStatus) {
        #expect(selectsForDeletion(status: status, creationOffset: -86_400))
        #expect(selectsForDeletion(status: status, creationOffset: nil))
    }

    // Pending records captured on/after the cutoff are kept.
    @Test(arguments: [
        CameraAssetUploadStatus.notStarted,
        .notReady,
        .cancelled,
        .failed
    ])
    func pendingPostCutoffRecordsAreKept(status: CameraAssetUploadStatus) {
        #expect(!selectsForDeletion(status: status, creationOffset: 0))
        #expect(!selectsForDeletion(status: status, creationOffset: 86_400))
    }

    // Completed and in-flight records are never deleted, regardless of capture date.
    @Test(arguments: [
        CameraAssetUploadStatus.done,
        .queuedUp,
        .processing,
        .uploading
    ])
    func completedAndInFlightRecordsAreNeverDeleted(status: CameraAssetUploadStatus) {
        #expect(!selectsForDeletion(status: status, creationOffset: -86_400))
        #expect(!selectsForDeletion(status: status, creationOffset: 86_400))
        #expect(!selectsForDeletion(status: status, creationOffset: nil))
    }
}
