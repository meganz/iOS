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

    @Published private(set) var isOfferExpired: Bool

    private let dependency: PromoLandingDialogContentView.Dependency

    init(dependency: PromoLandingDialogContentView.Dependency) {
        self.dependency = dependency
        self.isOfferExpired = dependency.promoExpiryTimer?.hasAlreadyExpired ?? false
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

    var viewAllPlans: ViewAllPlans {
        guard dependency.hasMultipleOffers || isOfferExpired else { return .hidden }

        let analytics = dependency.analytics
        let viewAllPlansAction = dependency.viewAllPlansAction
        return .shown(action: {
            analytics.trackViewAllPlansButtonPressed()
            viewAllPlansAction()
        })
    }

    // MARK: - Offer expiry

    /// Waits out the countdown so the footer can swap the buy button for "View all plans" the moment the offer lapses.
    func monitorOfferExpiry() async {
        guard let timer = dependency.promoExpiryTimer else { return }
        guard await timer.waitUntilExpired() else { return }
        guard !Task.isCancelled else { return }
        isOfferExpired = true
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
