import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

public extension PromoLandingDialogContentView {
    struct Dependency {
        /// The button that opens the upgrade page
        /// .hidden for the case of single offer, otherwise shown with an action to open Upgrade page
        enum ViewAllPlans {
            case hidden
            case shown(action: @MainActor () -> Void)
        }

        let plan: PlanEntity
        let planPurchaser: any PlanPurchasing
        let dismissAction: @MainActor () -> Void
        let onPurchased: @MainActor () -> Void
        let viewAllPlans: ViewAllPlans

        public init(
            fetchResult: PromotedPlanFetchResult,
            planPurchaser: some PlanPurchasing,
            dismissAction: @escaping @MainActor () -> Void,
            onPurchased: @escaping @MainActor () -> Void = {},
            viewAllPlansAction: @escaping @MainActor () -> Void
        ) {
            self.plan = fetchResult.promotedPlan.plan
            self.planPurchaser = planPurchaser
            self.dismissAction = dismissAction
            self.onPurchased = onPurchased
            self.viewAllPlans = fetchResult.hasMultipleOffers ? .shown(action: viewAllPlansAction) : .hidden
        }
    }
}
