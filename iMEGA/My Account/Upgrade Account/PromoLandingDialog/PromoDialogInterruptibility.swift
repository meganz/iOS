import MEGAAppPresentation
import MEGADomain
import QuotaWarnings
import UIKit

/// Whether the user can be interrupted right now by the promotional offer landing dialog.
///
/// The dialog is unprompted, so it should be suppressed when the user is busy with:
/// * an active call
/// * the passcode screen
/// * a modal alert
/// * a quota dialog
///
/// Anything else is interruptible. A skipped app open is simply skipped: the next foreground checks again.
@MainActor
protocol PromoDialogInterruptibilityProtocol {
    var canInterruptUser: Bool { get }
}

@MainActor
struct PromoDialogInterruptibility: PromoDialogInterruptibilityProtocol {
    private let chatUseCase: any ChatUseCaseProtocol
    private let topViewController: @MainActor () -> UIViewController?
    private let isLockScreenPresenting: @MainActor () -> Bool
    private let isAnotherDialogPresenting: @MainActor () -> Bool

    init(
        chatUseCase: some ChatUseCaseProtocol,
        topViewController: @escaping @MainActor () -> UIViewController? = {
            UIApplication.mnz_visibleViewController()
        },
        isLockScreenPresenting: @escaping @MainActor () -> Bool = {
            LTHPasscodeViewController.doesPasscodeExist()
                && LTHPasscodeViewController.sharedUser().isLockscreenPresent()
        },
        isAnotherDialogPresenting: @escaping @MainActor () -> Bool = {
            QuotaDialogPresentationState.shared.isPresenting
        }
    ) {
        self.chatUseCase = chatUseCase
        self.topViewController = topViewController
        self.isLockScreenPresenting = isLockScreenPresenting
        self.isAnotherDialogPresenting = isAnotherDialogPresenting
    }

    var canInterruptUser: Bool {
        !isLockScreenPresenting() && !chatUseCase.existsActiveCall() && !isOnBlockedScreen
            && !isAnotherDialogPresenting()
    }

    /// Screens the user must not be interrupted on: the modal alerts, a
    /// plan or payment flow they are already in, which includes the Upgrade screen forced on a free user at login.
    /// Each screen declares this about itself by conforming to `PromoDialogBlocking`.
    private var isOnBlockedScreen: Bool {
        topViewController() is any PromoDialogBlocking
    }
}
