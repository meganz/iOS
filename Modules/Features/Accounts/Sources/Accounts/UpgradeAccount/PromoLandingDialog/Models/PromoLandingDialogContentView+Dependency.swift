import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

public extension PromoLandingDialogContentView {
    struct Dependency {
        let plan: PlanEntity
        let hasMultipleOffers: Bool
        let planPurchaser: any PlanPurchasing
        let dismissAction: @MainActor () -> Void
        let onPurchased: @MainActor () -> Void
        let viewAllPlansAction: @MainActor () -> Void
        let analytics: PromoLandingDialogAnalytics

        public init(
            fetchResult: PromotedPlanFetchResult,
            launchSource: PromoLandingDialogAnalytics.LaunchSource,
            planPurchaser: some PlanPurchasing,
            dismissAction: @escaping @MainActor () -> Void,
            onPurchased: @escaping @MainActor () -> Void = {},
            viewAllPlansAction: @escaping @MainActor () -> Void,
            tracker: some AnalyticsTracking = DIContainer.tracker
        ) {
            self.plan = fetchResult.promotedPlan.plan
            self.hasMultipleOffers = fetchResult.hasMultipleOffers
            self.planPurchaser = planPurchaser
            self.dismissAction = dismissAction
            self.onPurchased = onPurchased
            self.viewAllPlansAction = viewAllPlansAction
            self.analytics = PromoLandingDialogAnalytics(launchSource: launchSource, tracker: tracker)
        }
    }
}
