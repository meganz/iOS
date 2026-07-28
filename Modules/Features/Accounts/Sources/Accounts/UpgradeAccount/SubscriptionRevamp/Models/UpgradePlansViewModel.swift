import MEGADomain
import MEGAL10n

/// Shared presentation model backing both redesigned subscription pages.
///
/// The standard and promo pages use the same type; promo-only content
/// (`promoHeader`, `highlightedPlanCard`) is `nil` on the standard page.
@MainActor
public final class UpgradePlansViewModel {
    private let isPromo: Bool
    private let viewType: RevampUpgradePlansViewType
    private let accountDetails: AccountDetailsEntity
    private let plans: [PlanEntity]
    private let displayName: @Sendable (AccountTypeEntity) -> String

    init(
        isPromo: Bool = false,
        viewType: RevampUpgradePlansViewType,
        accountDetails: AccountDetailsEntity,
        plans: [PlanEntity],
        displayName: @escaping @Sendable (AccountTypeEntity) -> String
    ) {
        self.isPromo = isPromo
        self.viewType = viewType
        self.accountDetails = accountDetails
        self.plans = plans
        self.displayName = displayName
    }

    private var currentPlanPresenter: SubscriptionCurrentPlanPresenter {
        SubscriptionCurrentPlanPresenter(
            accountDetails: accountDetails,
            plans: plans,
            displayName: displayName
        )
    }

    var promoHeader: SubscriptionPromoHeaderModel? {
        isPromo ? SubscriptionRevampMockData.promoHeader : nil
    }

    /// The featured hero card, shown only when exactly one plan is discounted.
    var highlightedPlanCard: SubscriptionRevampPromoPlanCardModel? {
        guard isPromo, let featuredPlan else { return nil }
        return SubscriptionPromoPlanCardPresenter(
            plan: featuredPlan,
            displayName: displayName
        ).cardModel
    }

    var currentPlanViewModel: SubscriptionCurrentPlanViewModel? {
        currentPlanPresenter.currentPlanViewModel
    }

    var freePlanCard: SubscriptionFreePlanCardModel? {
        guard case .onboarding(let isFreeAccountFirstLogin) = viewType else { return nil }
        return SubscriptionFreePlanCardModel(
            maxStorageSize: accountDetails.storageMax,
            isExistingFreeAccount: isFreeAccountFirstLogin
        )
    }

    // MARK: - Plan cards

    func planCards(for cycle: SubscriptionCycleEntity) -> [SubscriptionPlanCardModel] {
        SubscriptionPlanCardsPresenter(
            plans: plans,
            featuredPlan: featuredPlan,
            displayName: displayName
        ).cards(for: cycle)
    }

    // MARK: - Billing cycle

    private var cyclePresenter: SubscriptionCyclePresenter {
        SubscriptionCyclePresenter(plans: plans)
    }

    var cycleOptions: [SubscriptionCycleEntity] { cyclePresenter.options }

    func cycleTitle(_ cycle: SubscriptionCycleEntity) -> String {
        cyclePresenter.title(for: cycle)
    }

    var savingText: String? { cyclePresenter.savingText }

    // MARK: - Offers

    private var introOfferPlans: [PlanEntity] {
        plans.filter { $0.introductoryOffer != nil }
    }

    private var promoOfferPlans: [PlanEntity] {
        plans.filter { $0.hasValidPromotionalOffer }
    }

    /// Introductory offers take global priority for the layout decision; promo offers only count when there are no intro offers
    private var discountedPlans: [PlanEntity] {
        introOfferPlans.isEmpty ? promoOfferPlans : introOfferPlans
    }

    /// The single discounted plan when `offerCount == 1`; `nil` for zero or multiple (rendered inline).
    private var featuredPlan: PlanEntity? {
        discountedPlans.count == 1 ? discountedPlans.first : nil
    }
}
