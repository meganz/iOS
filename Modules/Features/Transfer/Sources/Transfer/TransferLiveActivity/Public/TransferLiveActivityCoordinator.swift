import Foundation

@available(iOS 16.2, *)
@MainActor
public final class TransferLiveActivityCoordinator {

    public static let shared = TransferLiveActivityCoordinator()

    private var manager: TransferLiveActivityManager?

    private init() {}

    public func startMonitoring() {
        guard manager == nil,
              let useCase = SharedTransferIndicator.useCase else { return }
        let manager = TransferLiveActivityManager(
            activityProvider: TransferLiveActivityProvider()
        )
        manager.startMonitoring(snapshotPublisher: useCase.snapshotPublisher)
        self.manager = manager
    }

    public func stopMonitoring() {
        manager?.stopMonitoring()
        manager = nil
    }

    /// Push a `.suspended` frame to the running Live Activity. Intended to be
    /// called from the AppDelegate background-task expiration handler so the LA
    /// stops showing data that's about to become stale once iOS suspends the
    /// process. No-op when no activity is running or when the last pushed state
    /// is terminal or warning (`.error`, `.overquota`, `.completed`).
    public func pushSuspendedState() {
        manager?.pushSuspendedState()
    }

    /// Clears the suspended-frame lock so subsequent snapshot updates can
    /// resume driving the activity. Call from the AppDelegate when the app
    /// returns to foreground.
    public func clearSuspendedLock() {
        manager?.clearSuspendedLock()
    }
}
