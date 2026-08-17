@testable import MEGA
import Testing

@Suite("IncompleteDownloadAlertRouter Tests - Verifies the warning never outlives what can show it.")
struct IncompleteDownloadAlertRouterTests {
    /// The caller awaits this warning while holding a finished download open, so a warning that cannot be
    /// shown has to return rather than wait. Waiting would strand the export: the share sheet never opens,
    /// the transfer widget never hides, and the folder link's Download button stays disabled for the rest of
    /// the session.
    ///
    /// Returning at all is the assertion. With no presenter there is nothing to await, so this completes
    /// without suspending; reintroducing the presentation on a nil presenter would leave a continuation
    /// unresumed and never come back here.
    @Test("no presenter returns instead of waiting on a dialog that will never appear", .timeLimit(.minutes(1)))
    @MainActor
    func noPresenter_returnsWithoutWaiting() async {
        let sut = IncompleteDownloadAlertRouter(presenter: { nil })

        await sut.warnDownloadIncomplete(downloadedCount: 3, failedCount: 2)
    }
}
