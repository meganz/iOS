import MEGADomain

/// Shared presentation model backing both redesigned subscription pages.
///
/// The standard and promo pages use the same type; promo-only content
/// (`promoHeader`, `highlightedPlanCard`) is `nil` on the standard page.
@MainActor
public final class RevampUpgradePlansViewModel {
    private let isPromo: Bool
    private let accountDetails: AccountDetailsEntity
    private let plans: [PlanEntity]
    private let displayName: @Sendable (AccountTypeEntity) -> String

    init(
        isPromo: Bool = false,
        accountDetails: AccountDetailsEntity,
        plans: [PlanEntity],
        displayName: @escaping @Sendable (AccountTypeEntity) -> String
    ) {
        self.isPromo = isPromo
        self.accountDetails = accountDetails
        self.plans = plans
        self.displayName = displayName
    }

    private var presenter: SubscriptionCurrentPlanPresenter {
        SubscriptionCurrentPlanPresenter(
            accountDetails: accountDetails,
            plans: plans,
            displayName: displayName
        )
    }

    var promoHeader: SubscriptionPromoHeaderModel? {
        isPromo ? SubscriptionRevampMockData.promoHeader : nil
    }

    var highlightedPlanCard: SubscriptionRevampPromoPlanCardModel? {
        isPromo ? SubscriptionRevampMockData.promoPlanCard : nil
    }

    var currentPlanViewModel: SubscriptionCurrentPlanViewModel? {
        presenter.currentPlanViewModel
    }

    var freePlanCard: SubscriptionFreePlanCardModel? {
        SubscriptionRevampMockData.freePlanCard
    }
}
