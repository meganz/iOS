import Foundation

// [IOS-12185]: Wire actual data to view model
@MainActor
final class SubscriptionRevampPromoViewModel {
    let promoHeader: SubscriptionPromoHeaderModel
    let highlightedPlanCard: SubscriptionRevampPromoPlanCardModel
    let features: [SubscriptionProFeature]
    let currentPlan: SubscriptionCurrentPlanViewModel
    let benefits: [String]

    init(
        promoHeader: SubscriptionPromoHeaderModel = SubscriptionRevampMockData.promoHeader,
        highlightedPlanCard: SubscriptionRevampPromoPlanCardModel = SubscriptionRevampMockData.promoPlanCard,
        features: [SubscriptionProFeature] = SubscriptionRevampMockData.features,
        currentPlan: SubscriptionCurrentPlanViewModel = SubscriptionRevampMockData.currentPlan,
        benefits: [String] = SubscriptionRevampMockData.benefits
    ) {
        self.promoHeader = promoHeader
        self.highlightedPlanCard = highlightedPlanCard
        self.features = features
        self.currentPlan = currentPlan
        self.benefits = benefits
    }
}
