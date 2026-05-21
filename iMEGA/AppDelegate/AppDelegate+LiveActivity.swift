import Foundation
import Transfer

extension AppDelegate {

    /// ObjC bridge for the background-task expiration handler in
    /// `beginBackgroundTaskWithName:`. When the `"PendingTasks"` task is about to
    /// expire and a transfer Live Activity is running in `.active` or `.paused`,
    /// push a final `.suspended` frame with cleared speed so the Lock Screen
    /// stops showing data that's about to become stale once iOS suspends the
    /// process. No-op for terminal or warning states.
    @objc func pushTransferLiveActivitySuspendedState() {
        guard #available(iOS 16.2, *) else { return }
        TransferLiveActivityCoordinator.shared.pushSuspendedState()
    }

    /// ObjC bridge for `applicationDidBecomeActive`. Clears the suspended-frame
    /// lock so the snapshot publisher can resume driving the Live Activity.
    @objc func clearTransferLiveActivitySuspendedLock() {
        if #available(iOS 16.2, *) {
            TransferLiveActivityCoordinator.shared.clearSuspendedLock()
        }
    }
}
