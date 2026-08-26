import Foundation
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
        // Timer to promo expiration, nil means no expiration 
        let promoExpiryTimer: (any PromoExpiryTiming)?
        let analytics: PromoLandingDialogAnalytics

        public init(
            fetchResult: PromotedPlanFetchResult,
            launchSource: PromoLandingDialogAnalytics.LaunchSource,
            planPurchaser: some PlanPurchasing,
            dismissAction: @escaping @MainActor () -> Void,
            onPurchased: @escaping @MainActor () -> Void = {},
            viewAllPlansAction: @escaping @MainActor () -> Void,
            makePromoExpiryTimer: (Date) -> any PromoExpiryTiming = PromoExpiryTimer.init(deadline:),
            tracker: some AnalyticsTracking = DIContainer.tracker
        ) {
            let plan = fetchResult.promotedPlan.plan
            self.plan = plan
            self.hasMultipleOffers = fetchResult.hasMultipleOffers
            self.planPurchaser = planPurchaser
            self.dismissAction = dismissAction
            self.onPurchased = onPurchased
            self.viewAllPlansAction = viewAllPlansAction
            self.promoExpiryTimer = plan.promotionExpiryDate.map(makePromoExpiryTimer)
            self.analytics = PromoLandingDialogAnalytics(launchSource: launchSource, tracker: tracker)
        }
    }
}
