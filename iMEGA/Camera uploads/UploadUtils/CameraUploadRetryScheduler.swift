import Foundation
import os

/// Decides when a previously failed record may take a slot while records that never failed are waiting,
/// so a few assets that keep failing can't hold every upload slot. Used per media type by `CameraUploadManager`.
@objc final class CameraUploadRetryScheduler: NSObject, Sendable {
    private struct State {
        var newRecordsSinceLastRetry = 0
        /// Earliest value of `newRecordsSinceLastRetry` at which a retry is looked for again.
        var nextRetryCheck: Int
    }

    private let baseInterval: Int
    private let state: OSAllocatedUnfairLock<State>

    init(baseInterval: Int) {
        self.baseInterval = baseInterval
        state = OSAllocatedUnfairLock(initialState: State(nextRetryCheck: baseInterval))
    }

    @objc override convenience init() {
        self.init(baseInterval: 3)
    }

    /// Chooses the next record to queue up. A retry is served after `baseInterval × 2^failureCount` never-failed records,
    /// at most one runs at a time, and none when there is a single slot. The lookups are called only when a retry could
    /// be served, and at most once per `baseInterval` picks, so most picks cost no lookup at all.
    /// - Parameters:
    ///   - neverFailedRecord: The newest record that never failed, if any.
    ///   - concurrentCount: The upload queue's maximum concurrent operation count.
    ///   - failedRecord: Looks up the next previously failed record.
    ///   - failureCount: How many times the given failed record failed in this launch.
    ///   - runningRetryCount: Counts previously failed records that are queued up or processing.
    /// - Returns: The record to queue up, or nil when there is none.
    @objc func nextRecord(
        neverFailedRecord: Any?,
        concurrentCount: Int,
        failedRecord: () -> Any?,
        failureCount: (Any) -> Int,
        runningRetryCount: () -> Int
    ) -> Any? {
        guard let neverFailedRecord else { return failedRecord() }

        let current = state.withLock { $0 }
        if current.newRecordsSinceLastRetry >= current.nextRetryCheck {
            let retry = dueRetry(
                newRecords: current.newRecordsSinceLastRetry,
                concurrentCount: concurrentCount,
                failedRecord: failedRecord,
                failureCount: failureCount,
                runningRetryCount: runningRetryCount
            )
            if let retry {
                state.withLock { $0 = State(nextRetryCheck: baseInterval) }
                return retry
            }
        }

        state.withLock { $0.newRecordsSinceLastRetry += 1 }
        return neverFailedRecord
    }

    private func dueRetry(
        newRecords: Int,
        concurrentCount: Int,
        failedRecord: () -> Any?,
        failureCount: (Any) -> Int,
        runningRetryCount: () -> Int
    ) -> Any? {
        // A retry often holds its slot for minutes, so it must never take the only one.
        let maxRunningRetries = min(1, concurrentCount - 1)
        guard maxRunningRetries > 0, let candidate = failedRecord() else {
            deferRetryCheck(until: newRecords + baseInterval)
            return nil
        }

        // The per-launch retry limit keeps failure counts small; the cap only guards the shift.
        let interval = baseInterval << min(max(failureCount(candidate), 0), 16)
        guard newRecords >= interval else {
            deferRetryCheck(until: interval)
            return nil
        }

        guard runningRetryCount() < maxRunningRetries else {
            deferRetryCheck(until: newRecords + baseInterval)
            return nil
        }

        return candidate
    }

    private func deferRetryCheck(until newRecords: Int) {
        state.withLock { $0.nextRetryCheck = newRecords }
    }
}
