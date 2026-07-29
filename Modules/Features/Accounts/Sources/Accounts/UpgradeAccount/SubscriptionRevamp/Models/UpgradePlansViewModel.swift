import Combine
import MEGADomain

/// Shared presentation model backing both redesigned subscription pages.
///
/// The standard and promo pages use the same type; promo-only content
/// (`promoHeader`, `highlightedPlanCard`) is `nil` on the standard page.
@MainActor
public final class UpgradePlansViewModel: ObservableObject {
    private let isPromo: Bool
    private let viewType: RevampUpgradePlansViewType
    private let accountDetails: AccountDetailsEntity
    let plans: [PlanEntity]
    /// The user's current billing cycle, used to build the cycle picker and its default selection.
    let currentCycle: SubscriptionCycleEntity
    private let displayName: @Sendable (AccountTypeEntity) -> String

    /// The billing cycle currently selected in the picker, seeded from the default selection.
    @Published var selectedCycle: SubscriptionCycleEntity

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
        self.currentCycle = accountDetails.subscriptionCycle
        self.displayName = displayName
        self.selectedCycle = Self.resolveDefaultCycle(plans: plans, currentCycle: accountDetails.subscriptionCycle)
    }

    private var currentPlanPresenter: SubscriptionCurrentPlanPresenter {
        SubscriptionCurrentPlanPresenter(
            accountDetails: accountDetails,
            plans: plans,
            displayName: displayName
        )
    }

    var promoHeader: SubscriptionPromoHeaderViewModel? {
        guard isPromo else { return nil }
        return SubscriptionPromoHeaderViewModel(plans: plans)
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

    // MARK: - Default cycle selection

    /// The billing cycle to preselect in priority order:
    /// 1. discounts on both cycles -> the cycle matching the user's current plan,
    /// 2. a discount on a single cycle -> that cycle,
    /// 3. no discount -> the user's current cycle, or yearly when the user has none (e.g. free).
    var defaultSelectedCycle: SubscriptionCycleEntity {
        Self.resolveDefaultCycle(plans: plans, currentCycle: currentCycle)
    }

    private static func resolveDefaultCycle(
        plans: [PlanEntity],
        currentCycle: SubscriptionCycleEntity
    ) -> SubscriptionCycleEntity {
        switch (hasDiscountedPlan(.monthly, in: plans), hasDiscountedPlan(.yearly, in: plans)) {
        case (true, false): .monthly
        case (false, true): .yearly
        case (true, true), (false, false): userCycle(currentCycle) ?? .yearly
        }
    }

    private static func hasDiscountedPlan(_ cycle: SubscriptionCycleEntity, in plans: [PlanEntity]) -> Bool {
        plans.contains { $0.subscriptionCycle == cycle && isDiscounted($0) }
    }

    private static func isDiscounted(_ plan: PlanEntity) -> Bool {
        plan.introductoryOffer != nil || plan.hasValidPromotionalOffer
    }

    private static func userCycle(_ cycle: SubscriptionCycleEntity) -> SubscriptionCycleEntity? {
        switch cycle {
        case .monthly: .monthly
        case .yearly: .yearly
        case .none: nil
        }
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

    // MARK: - Offers
    /// Introductory offers take global priority for the layout decision; promo offers only count when there are no intro offers
    private var discountedPlans: [PlanEntity] {
        plans.filter { $0.applicableOffer != nil }
    }

    /// The single discounted plan when `offerCount == 1`; `nil` for zero or multiple (rendered inline).
    private var featuredPlan: PlanEntity? {
        discountedPlans.count == 1 ? discountedPlans.first : nil
    }
}
