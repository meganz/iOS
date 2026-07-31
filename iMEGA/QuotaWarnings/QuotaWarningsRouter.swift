@preconcurrency import Combine
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift
import QuotaWarnings
import SwiftUI
import UIKit

@MainActor
@objc final class QuotaWarningsRouter: NSObject {
    static var isDialogPresenting: Bool = false
    
    private var isRedesignEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .quotaWarningsRevamp)
    }

    @objc func presentStorageQuotaWarning(event: MEGAEvent) {
        Task { @MainActor in
            if isRedesignEnabled {
                let severity: StorageQuotaSeverity = event.number == StorageState.orange.rawValue ? .almostFull : .full
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
                presentStorageDialog(severity: error.type == .apiEOverQuota ? .full : .almostFull)
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
            presentQuotaDialog(for: .transfer(severity))
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
                }
            ).start()
        }
    }

    /// Presents the redesigned storage quota dialog directly (guarded against stacking). For callers that
    /// have already resolved the feature flag and own their own legacy fallback, e.g. album-import.
    func presentStorageDialog(severity: StorageQuotaSeverity) {
        presentQuotaDialog(for: .storage(severity))
    }

    /// Presents a quota dialog, wrapped in a navigation controller for its toolbar close button.
    /// Skips presentation when a quota dialog is already visible
    private func presentQuotaDialog(for kind: QuotaWarningDialogView.Kind) {
        guard !QuotaWarningsRouter.isDialogPresenting else { return }
        QuotaWarningsRouter.isDialogPresenting = true
        let presenter = UIApplication.mnz_presentingViewController()
        let onClose: @MainActor () -> Void = { [weak presenter] in
            presenter?.dismiss(animated: true)
            QuotaWarningsRouter.isDialogPresenting = false
        }

        weak var presentedNavigationController: MEGANavigationController?
        let onViewAllPlans: @MainActor () -> Void = {
            guard let navigationController = presentedNavigationController else { return }
            Self.presentAllPlans(from: navigationController)
        }

        let purchaseUseCase = AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo)
        let dependency: QuotaWarningDialogView.Dependency = QuotaWarningDialogView.Dependency(
            accountPlanPurchaseUseCase: purchaseUseCase,
            pricingRequester: PricingRequester.shared,
            planPurchaser: PlanPurchaser(purchaseUseCase: purchaseUseCase, postPurchaseDelay: 0)
        )
        let hostingController = QuotaWarningDialogHostingController(
            rootView: QuotaWarningDialogView(
                dependency: dependency,
                kind: kind,
                onClose: onClose,
                onViewAllPlans: onViewAllPlans
            )
        )
        let navigationController = MEGANavigationController(rootViewController: hostingController)
        presentedNavigationController = navigationController
        presenter.present(navigationController, animated: true)
    }

    private static func presentAllPlans(from navigationController: UINavigationController) {
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
                navigationController?.dismiss(animated: true)
                QuotaWarningsRouter.isDialogPresenting = false
            }
        ).start()
    }
}

private final class QuotaWarningDialogHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
    }
    
    deinit {
        Task { @MainActor in
            QuotaWarningsRouter.isDialogPresenting = false
        }
    }
}
