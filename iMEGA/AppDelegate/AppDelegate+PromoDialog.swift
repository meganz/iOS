import ChatRepo
import MEGADomain

/// The app-open trigger for the promotional offer landing dialog.
///
/// Called from two places, because a launch and a return from the background are not the same event:
///   * `processActionsAfterSetRootVC`, once the tab bar is the window root and any passcode has been entered. A
///     free user's forced Upgrade screen at login does not go through there, which is what keeps the dialog out
///     of that flow.
///   * `applicationWillEnterForeground:`, for a return to an app that is already set up.
extension AppDelegate {
    @objc func showPromoLandingDialogIfNeeded() {
        Task { @MainActor in
            PromoLandingDialogLaunchPresenter.shared.triggerIfNeeded()
        }
    }

    /// Drops a pending attempt, so the dialog is never presented into a backgrounded app.
    @objc func cancelPromoLandingDialogTrigger() {
        Task { @MainActor in
            PromoLandingDialogLaunchPresenter.shared.cancel()
        }
    }

    @objc func shouldIgnoreUpgradeLink(_ url: URL) -> Bool {
        guard url.mnz_isUpgradeLink else { return false }
        return !PromoDialogInterruptibility(chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo)).canInterruptUser
    }
}
