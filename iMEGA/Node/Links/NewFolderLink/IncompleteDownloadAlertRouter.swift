import MEGAL10n
import UIKit

/// Warns that a batch download came back short before the files it did fetch are handed on.
///
/// Deliberately says nothing about why the rest failed: the SDK reports a bare write error for a disk that
/// filled up mid transfer, so the copy points at Transfers rather than guessing at a cause.
final class IncompleteDownloadAlertRouter: IncompleteDownloadAlertRouting {
    /// Asked for the presenter when the warning is raised rather than handed one up front: a download runs
    /// for as long as it takes, and what can present by the time it ends is not what could when it started.
    private let presenter: @MainActor () -> UIViewController?

    init(presenter: @escaping @MainActor () -> UIViewController? = { UIApplication.topPresentableViewController() }) {
        self.presenter = presenter
    }

    func warnDownloadIncomplete(downloadedCount: Int, failedCount: Int) async {
        // Resolved as an optional, unlike `UIApplication.mnz_presentingViewController()`, whose _Nonnull
        // declaration hides the nil it returns when there is no key window.
        guard let presentingViewController = presenter() else { return }

        await withCheckedContinuation { continuation in
            let resumer = ContinuationResumer(continuation)

            let alertController = UIAlertController(
                title: Strings.Localizable.Link.Download.Incomplete.title(failedCount),
                message: Strings.Localizable.Link.Download.Incomplete.message(downloadedCount),
                preferredStyle: .alert
            )
            alertController.addAction(
                UIAlertAction(title: dismissTitle(downloadedCount: downloadedCount), style: .default) { [resumer] _ in
                    resumer.resume()
                }
            )

            // Settled rather than straight away, because `topPresentableViewController()` hands back a
            // controller that is still animating in — presentable a moment later, but able to swallow a
            // presentation made into its in flight transition.
            presentingViewController.presentWhenSettled(alertController)
        }
    }

    /// Continue only promises something when there is an export left to continue to, so a batch that
    /// produced nothing at all closes on OK instead.
    private func dismissTitle(downloadedCount: Int) -> String {
        downloadedCount > 0 ? Strings.Localizable.continue : Strings.Localizable.ok
    }
}

/// Resumes a continuation exactly once, on being asked or on being deallocated.
///
/// Deallocation is the point of it: it covers every way the wait can end by releasing whatever was going to
/// resume, rather than by calling anything. Whoever holds one of these therefore owns the obligation to
/// resume, and dropping it discharges that obligation instead of losing it.
///
/// Isolated rather than synchronised: both callers are already on the main actor — the alert's action, and a
/// deallocation that `isolated deinit` brings here too — so the actor is what keeps the resume single, with
/// no lock and nothing to declare unchecked.
@MainActor
private final class ContinuationResumer {
    private var continuation: CheckedContinuation<Void, Never>?

    init(_ continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
    }

    isolated deinit {
        resume()
    }

    func resume() {
        // Cleared as it is taken, so a second call finds nothing rather than resuming twice.
        continuation?.resume()
        continuation = nil
    }
}
