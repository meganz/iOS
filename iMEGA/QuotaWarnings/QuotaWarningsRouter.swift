import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAudioPlayer
import MEGADomain
import MEGASdk
import MEGASwift
import QuotaWarnings
import SwiftUI
import UIKit

@MainActor
@objc final class QuotaWarningsRouter: NSObject {
    static var isLockScreenPresenting: Bool {
        LTHPasscodeViewController.sharedUser().isLockscreenPresent()
    }
    
    /// Presents the redesigned storage quota dialog.
    /// - Returns: whether the dialog was presented. Callers with a daily display limit must only call `recordDialogShown()` when this is `true`.
    /// See `StorageAlmostFullDialogUseCaseProtocol` 
    @discardableResult
    func presentStorageDialog(severity: StorageQuotaSeverity) -> Bool {
        presentQuotaDialog(for: .storage(severity))
    }

    /// Presents the redesigned transfer quota dialog
    /// - Returns: whether the dialog was presented.
    @discardableResult
    func presentTransferDialog(severity: TransferQuotaSeverity) -> Bool {
        presentQuotaDialog(for: .transfer(severity))
    }

    // MARK: - Privates

    /// Presents a quota dialog, wrapped in a navigation controller for its toolbar close button.
    /// Skips presentation when a quota dialog is already visible, or when nothing on screen can present one.
    private func presentQuotaDialog(for kind: QuotaWarningDialogView.Kind) -> Bool {
        /// Avoid preseting quota dialog on top of the lock screen
        ///  The app-open trigger re-runs from processActionsAfterSetRootVC once the passcode is entered.
        ///  The successful upload trigger will be skipped to next upload.
        guard !QuotaWarningsRouter.isLockScreenPresenting else { return false }

        /// Resolve the presenter before claiming the slot below. Presenting on a controller that is off window is a
        /// silent no-op, and claiming first would then strand the slot and block every later dialog. Skipping this
        /// trigger is the same outcome the dialog has today, minus the lockout. A presenter that is still animating
        /// in is fine here - `presentWhenSettled(_:animated:)` waits for its transition instead of dropping the dialog.
        guard let presenter = UIApplication.topPresentableViewController() else {
            MEGALogError("[QuotaWarningsRouter]: No view controller available to present the quota dialog")
            return false
        }

        /// Only one dialog presented at a time
        guard QuotaDialogPresentationState.shared.beginPresenting() else { return false }

        let dismissHandler = QuotaDialogDismissHandler(
            kind: kind,
            dependency: .init(audioTearDownHandler: AudioTearDownHandlerFactory.make())
        )

        let onClose: @MainActor () -> Void = { [weak presenter] in
            guard let presenter else {
                dismissHandler.dismiss()
                return
            }
            presenter.dismiss(animated: true, completion: dismissHandler.dismiss)
        }

        weak var presentedNavigationController: MEGANavigationController?
        let onViewAllPlans: @MainActor () -> Void = {
            guard let navigationController = presentedNavigationController else { return }
            Self.presentAllPlans(from: navigationController, dismissHandler: dismissHandler)
        }

        let onSignIn: @MainActor () -> Void = { [weak presenter] in
            let startLogin: @MainActor () -> Void = {
                Task {
                    await dismissHandler.handleDismiss()
                    LoginViewRouter(presenter: UIApplication.mnz_presentingViewController()).start()
                }
            }
            guard let presenter else {
                startLogin()
                return
            }
            presenter.dismiss(animated: true, completion: startLogin)
        }

        let purchaseUseCase = AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo)
        let dependency: QuotaWarningDialogView.Dependency = QuotaWarningDialogView.Dependency(
            accountPlanPurchaseUseCase: purchaseUseCase,
            pricingRequester: PricingRequester.shared,
            planPurchaser: PlanPurchaser(
                purchaseUseCase: purchaseUseCase,
                tracker: DIContainer.tracker,
                postPurchaseDelay: 0
            )
        )
        let hostingController = QuotaWarningDialogHostingController(
            dependency: dependency,
            kind: kind,
            onClose: onClose,
            onViewAllPlans: onViewAllPlans,
            onSignIn: onSignIn,
            dismissHandler: dismissHandler
        )
        let navigationController = MEGANavigationController(rootViewController: hostingController)
        presentedNavigationController = navigationController
        navigationController.presentationController?.delegate = hostingController
        presenter.presentWhenSettled(navigationController)
        return true
    }

    private static func presentAllPlans(
        from navigationController: UINavigationController,
        dismissHandler: some QuotaDialogDismissHandling
    ) {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        guard let currentAccountDetails = accountUseCase.currentAccountDetails else {
            MEGALogError("[QuotaWarningsRouter]: Could not retrieve current account details")
            return
        }
        SubscriptionPurchaseRouter(
            presenter: navigationController,
            currentAccountDetails: currentAccountDetails,
            presentationStyle: .push,
            viewType: .upgrade,
            accountUseCase: accountUseCase,
            onDismiss: { [weak navigationController] in
                // Back / "maybe later" → return to the quota dialog.
                navigationController?.popViewController(animated: true)
            },
            purchaseCompleteBehavior: .perform { [weak navigationController] in
                // Purchase completed on the pushed subscription page → dismiss the whole quota dialog
                // (this navigation controller), not just pop back to the now-stale dialog.
                guard let navigationController else {
                    dismissHandler.dismiss()
                    return
                }
                navigationController.dismiss(animated: true, completion: dismissHandler.dismiss)
            }
        ).start()
    }
}

// MARK: - QuotaWarningDialogHostingController
private final class QuotaWarningDialogHostingController: UIHostingController<QuotaWarningDialogView>, UIAdaptivePresentationControllerDelegate {
    private let dismissHandler: any QuotaDialogDismissHandling

    init(
        dependency: QuotaWarningDialogView.Dependency,
        kind: QuotaWarningDialogView.Kind,
        onClose: @escaping @MainActor () -> Void,
        onViewAllPlans: @escaping @MainActor () -> Void,
        onSignIn: @escaping @MainActor () -> Void,
        dismissHandler: some QuotaDialogDismissHandling
    ) {
        self.dismissHandler = dismissHandler
        super.init(
            rootView: QuotaWarningDialogView(
                dependency: dependency,
                kind: kind,
                onClose: onClose,
                onViewAllPlans: onViewAllPlans,
                onSignIn: onSignIn
            )
        )
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
    }

    @objc func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissHandler.dismiss()
    }
}

// MARK: - Legacy flow compatibility
extension QuotaWarningsRouter {
    private var isRedesignEnabled: Bool {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosQuotaWarningsRevamp)
    }

    @objc func presentStorageQuotaWarning(event: MEGAEvent) {
        Task { @MainActor in
            if isRedesignEnabled {
                // Only red reaches this path — almost full is checked on app open and after a
                // successful upload instead. The ternary is left as defensive code.
                let severity: StorageQuotaSeverity = event.number == StorageState.orange.rawValue ? .almostFull : .full(.storageState)
                presentStorageDialog(severity: severity)
            } else {
                // Old logic, copied over
                CustomModalAlertStorageRouter(
                    .storageEvent,
                    event: event,
                    presenter: UIApplication.mnz_presentingViewController()
                ).start()
            }
        }
    }
    
    @objc func presentStorageQuotaWarning(error: MEGAError, legacyMode: CustomModalAlertMode) {
        Task { @MainActor in
            if isRedesignEnabled {
                // `storageUploadQuotaError` is the only mode raised by a blocked upload, so it is
                // the only one that gets the "continue uploading" copy.
                let trigger: StorageQuotaSeverity.FullTrigger = legacyMode == .storageUploadQuotaError ? .uploadAttempt : .storageState
                presentStorageDialog(severity: error.type == .apiEOverQuota ? .full(trigger) : .almostFull)
            } else {
                CustomModalAlertRouter(
                    legacyMode,
                    presenter: UIApplication.mnz_presentingViewController()
                ).start()
            }
        }
    }

    func presentTransferQuotaWarning(mode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode) {
        let presenter = UIApplication.mnz_presentingViewController()

        if isRedesignEnabled {
            let severity: TransferQuotaSeverity = switch mode {
            case .limitedDownload: .limitedDownload
            case .downloadExceeded: .downloadExceeded
            case .streamingExceeded: .streamingExceeded
            }
            presentTransferDialog(severity: severity)
        } else {
            // Old logic, copied over
            CustomModalAlertRouter(
                .transferDownloadQuotaError,
                presenter: presenter,
                transferQuotaDisplayMode: mode,
                actionHandler: { completion in
                    if AudioPlayerManager.shared.isPlayerAlive() {
                        Task {
                            await AudioPlayerManager.shared.dismissFullScreenPlayer()
                            AudioPlayerManager.shared.closePlayer()
                            completion()
                        }
                    } else {
                        completion()
                    }
                },
                dismissHandler: {
                    if AudioPlayerManager.shared.isPlayerAlive() {
                        Task {
                            await AudioPlayerManager.shared.dismissFullScreenPlayer()
                            AudioPlayerManager.shared.closePlayer()
                        }
                    }
                    if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .audioPlayerRevamp) || DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosAudioPlayerRevamp) {
                        MEGAAudioPlayerSession.stop()
                    }
                }
            ).start()
        }
    }
}
