import Accounts
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

@MainActor
final class AppOpenPromoLandingDialogRouter {
    // MARK: - Presentation

    /// Nothing is presented when no view controller can take a presentation right now
    /// - Returns: whether the dialog was presented, so a caller gating on a reshow interval only records the
    ///   campaign as shown when it actually was.
    @discardableResult
    func present(plan: PlanEntity) -> Bool {
        guard let presenter = UIApplication.topPresentableViewController() else {
            MEGALogError("[PromoLandingDialog] No view controller available to present the landing dialog")
            return false
        }

        let onDismiss: @MainActor () -> Void = { [weak presenter] in
            presenter?.dismiss(animated: true)
        }

        let dependency = PromoLandingDialogContentView.Dependency(
            plan: plan,
            planPurchaser: makePlanPurchaser(),
            dismissAction: onDismiss
        )

        let hostingController = PromoLandingDialogContentHostingController(dependency: dependency)
        hostingController.modalPresentationStyle = .automatic
        presenter.presentWhenSettled(hostingController)
        return true
    }

    // MARK: - Wiring

    private func makePlanPurchaser() -> some PlanPurchasing {
        PlanPurchaser(
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            tracker: DIContainer.tracker,
            postPurchaseDelay: 0
        )
    }
}

// MARK: - PromoLandingDialogContentHostingController

/// Internal rather than `private` so a test can pin the `PromoDialogBlocking` conformance.
final class PromoLandingDialogContentHostingController: UIHostingController<PromoLandingDialogContentView> {
    init(
        dependency: PromoLandingDialogContentView.Dependency
    ) {
        super.init(
            rootView: PromoLandingDialogContentView(dependency: dependency)
        )
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PromoDialogBlocking

/// Promo dialog is itself a `PromoDialogBlocking` which prevents multiple promo dialogs stack on top each other.
extension PromoLandingDialogContentHostingController: PromoDialogBlocking {}
