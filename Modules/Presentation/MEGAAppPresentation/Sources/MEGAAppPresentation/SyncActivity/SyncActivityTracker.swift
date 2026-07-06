import Combine
import Foundation

/// Tracks bursts of account update activity (e.g. node updates from action-packet catch-up)
/// and derives whether a "syncing" indicator should be shown.
///
/// Burst semantics: counts accumulate across consecutive `trackActivity` calls, `isSyncing`
/// becomes `true` once the cumulative count crosses `batchThreshold`, stays `true` while
/// activity keeps arriving, and resets to `false` (clearing the burst) only after
/// `quietInterval` without any activity — so the indicator never sticks, and it does not
/// flicker between waves of a long catch-up delivered in segments.
///
/// The thresholds are display-timing policy (when it is worth showing an indicator to the
/// user), which is why this type lives in the presentation layer rather than Domain.
@MainActor
public final class SyncActivityTracker: ObservableObject {
    @Published public private(set) var isSyncing = false

    private let batchThreshold: Int
    private let quietInterval: Duration
    private var burstCount = 0
    private var hideTask: Task<Void, Never>?

    /// - Parameters:
    ///   - batchThreshold: Minimum cumulative activity count in a burst before `isSyncing`
    ///     becomes `true`, so trivial single-item changes don't flash the indicator.
    ///   - quietInterval: How long activity must be quiet before the burst is considered
    ///     settled — `isSyncing` returns to `false` and the accumulated count resets.
    public init(batchThreshold: Int = 50, quietInterval: Duration = .seconds(2)) {
        self.batchThreshold = batchThreshold
        self.quietInterval = quietInterval
    }

    deinit {
        hideTask?.cancel()
    }

    public func trackActivity(count: Int) {
        burstCount += count
        // Only publish actual transitions — @Published emits on every write regardless of
        // value equality, and each emission invalidates every observing view.
        if burstCount >= batchThreshold, !isSyncing {
            isSyncing = true
        }

        hideTask?.cancel()
        hideTask = Task { [weak self, quietInterval] in
            try? await Task.sleep(for: quietInterval)
            guard !Task.isCancelled, let self else { return }
            if isSyncing {
                isSyncing = false
            }
            burstCount = 0
        }
    }
}
