import Combine
import MEGAAppPresentation
import MEGADomain

@MainActor
final class PromoLandingDialogContentViewModel: ObservableObject {
    /// The button that opens the upgrade page
    /// .hidden for the case of single offer, otherwise shown with an action to open Upgrade page
    enum ViewAllPlans {
        case hidden
        case shown(action: @MainActor () -> Void)
    }

    let viewAllPlans: ViewAllPlans

    private let dependency: PromoLandingDialogContentView.Dependency

    init(dependency: PromoLandingDialogContentView.Dependency) {
        self.dependency = dependency

        let analytics = dependency.analytics
        let viewAllPlansAction = dependency.viewAllPlansAction
        self.viewAllPlans = dependency.hasMultipleOffers
            ? .shown(action: {
                analytics.trackViewAllPlansButtonPressed()
                viewAllPlansAction()
            })
            : .hidden
    }

    // MARK: - Content

    var plan: PlanEntity {
        dependency.plan
    }

    var planPurchaser: any PlanPurchasing {
        dependency.planPurchaser
    }

    var purchaseTracker: any PlanPurchaseTracking {
        dependency.analytics
    }

    // MARK: - Actions

    func onAppear() {
        dependency.analytics.trackScreenViewed()
    }

    /// Reports the dismissal, unlike `purchaseCompleted`, so closing the dialog after a purchase is not
    /// counted as a dismiss press.
    func closeButtonTapped() {
        dependency.analytics.trackDismissButtonPressed()
        dependency.dismissAction()
    }

    /// Closes the dialog once the purchase lands. It reports no dismissal, because the user dismissed nothing.
    func purchaseCompleted() {
        dependency.onPurchased()
        dependency.dismissAction()
    }
}
