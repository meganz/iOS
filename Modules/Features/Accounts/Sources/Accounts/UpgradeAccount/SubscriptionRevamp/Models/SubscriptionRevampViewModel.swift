import Foundation
import MEGAL10n

/// Shared presentation model backing both redesigned subscription pages.
///
/// The standard and promo pages use the same type; promo-only content
/// (`promoHeader`, `highlightedPlanCard`) is `nil` on the standard page.
@MainActor
final class RevampUpgradePlansViewModel { // [IOS-12185]: Wire actual data to view model
    private let isPromo: Bool

    init(isPromo: Bool = false) {
        self.isPromo = isPromo
    }

    var promoHeader: SubscriptionPromoHeaderModel? {
        isPromo ? SubscriptionRevampMockData.promoHeader : nil
    }

    var highlightedPlanCard: SubscriptionRevampPromoPlanCardModel? {
        isPromo ? SubscriptionRevampMockData.promoPlanCard : nil
    }

    var currentPlan: SubscriptionCurrentPlanViewModel {
        SubscriptionRevampMockData.currentPlan
    }

    var freePlanCard: SubscriptionFreePlanCardModel? {
        SubscriptionRevampMockData.freePlanCard
    }

    static var standard: RevampUpgradePlansViewModel { // To be removed, temporarily used for testing purpose
        RevampUpgradePlansViewModel()
    }

    static var promo: RevampUpgradePlansViewModel { // To be removed, temporarily used for testing purpose
        RevampUpgradePlansViewModel(isPromo: true)
    }
}
