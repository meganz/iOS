import Combine
import Foundation
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
    /// Whether "buy on our website" is offered at all, so the button can be mapped onto the cards.
    private let isExternalPurchaseAvailable: Bool
    private let recommendedPlanUseCase: any RecommendedUpgradePlanUseCaseProtocol

    /// The billing cycle currently selected in the picker, always yearly by default.
    @Published var selectedCycle: SubscriptionCycleEntity = .yearly

    init(
        isPromo: Bool = false,
        viewType: RevampUpgradePlansViewType,
        accountDetails: AccountDetailsEntity,
        plans: [PlanEntity],
        displayName: @escaping @Sendable (AccountTypeEntity) -> String,
        isExternalPurchaseAvailable: Bool = false,
        recommendedPlanUseCase: some RecommendedUpgradePlanUseCaseProtocol
            = RecommendedUpgradePlanUseCase(subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase())
    ) {
        self.isPromo = isPromo
        self.viewType = viewType
        self.accountDetails = accountDetails
        self.plans = plans
        self.currentCycle = accountDetails.subscriptionCycle
        self.displayName = displayName
        self.isExternalPurchaseAvailable = isExternalPurchaseAvailable
        self.recommendedPlanUseCase = recommendedPlanUseCase
    }

    private var currentPlanPresenter: SubscriptionCurrentPlanPresenter {
        SubscriptionCurrentPlanPresenter(
            accountDetails: accountDetails,
            plans: plans,
            displayName: displayName
        )
    }

    private(set) lazy var promoHeader: SubscriptionPromoHeaderViewModel? = {
        guard isPromo else { return nil }
        return SubscriptionPromoHeaderViewModel(plan: promoHeaderPlan)
    }()

    /// The promotional offer's expiry that drives the header countdown, when one applies.
    /// `nil` for the standard page or for offers that never expire (introductory offers).
    var promoCountdownDeadline: Date? {
        promoHeader?.countdownDeadline
    }

    /// The featured hero card, shown only when exactly one plan is discounted.
    private(set) lazy var highlightedPlanCard: SubscriptionRevampPromoPlanCardModel? = {
        guard let featuredPlan else { return nil }
        return SubscriptionPromoPlanCardPresenter(
            plan: featuredPlan,
            displayName: displayName
        ).cardModel
    }()

    private(set) lazy var currentPlanViewModel: SubscriptionCurrentPlanViewModel? = {
        currentPlanPresenter.currentPlanViewModel
    }()

    /// Whether the user already holds the top plan, so no in-app upgrade is left to offer.
    var isOnHighestPlan: Bool {
        accountDetails.proLevel == .proIII
    }

    // MARK: - Default cycle selection

    /// The billing cycle to preselect, always yearly.
    var defaultSelectedCycle: SubscriptionCycleEntity { .yearly }

    var freePlanCard: SubscriptionFreePlanCardModel? {
        guard case .onboarding(let isFreeAccountFirstLogin) = viewType else { return nil }
        return SubscriptionFreePlanCardModel(
            maxStorageSize: accountDetails.storageMax,
            isExistingFreeAccount: isFreeAccountFirstLogin
        )
    }

    // MARK: - Plan cards

    /// The tier tagged as recommended in the given cycle; `nil` on the promo page and when that cycle
    /// offers no plan clearing the account's quota.
    /// Resolved per cycle, not once: the two catalogs need not hold the same tiers, so a tier recommended
    /// in one cycle may be missing from the other, which would leave that list with no ribbon at all.
    private func recommendedPlanType(for cycle: SubscriptionCycleEntity) -> AccountTypeEntity? {
        guard !isPromo,
              let recommended = recommendedPlanUseCase.recommend(
                  for: accountDetails,
                  from: plans,
                  cycleTarget: .specific(cycle: cycle)
              ) else { return nil }
        return plans.first { $0.productIdentifier == recommended.productIdentifier }?.type
    }

    func planCards(for cycle: SubscriptionCycleEntity) -> [SubscriptionPlanCardModel] {
        SubscriptionPlanCardsPresenter(
            plans: plans.filter { !$0.isCurrentPlan(for: accountDetails) },
            pageType: isPromo
                ? .promo(featuredPlan: featuredPlan)
                : .standard(recommendedPlanType: recommendedPlanType(for: cycle)),
            displayName: displayName,
            externalPurchase: isExternalPurchaseAvailable ? ExternalPurchasePresenter() : nil
        ).cards(for: cycle)
    }

    // MARK: - Offers
    /// Introductory offers take global priority for the layout decision; promo offers only count when there are no intro offers
    private var discountedPlans: [PlanEntity] {
        plans.filter { $0.applicableOffer != nil }
    }

    /// The single discounted plan when `offerCount == 1`; `nil` for zero or multiple (rendered inline),
    /// and on the standard page. Never the user's current plan, so the hero card cannot feature a plan
    /// the user already owns.
    var featuredPlan: PlanEntity? {
        guard isPromo,
              discountedPlans.count == 1,
              let plan = discountedPlans.first,
              !plan.isCurrentPlan(for: accountDetails) else { return nil }
        return plan
    }

    /// The plan the user already owns. Never rendered as a card, so no advertised discount may come from it.
    var currentPlan: PlanEntity? {
        plans.first { $0.isCurrentPlan(for: accountDetails) }
    }

    // The plan whose info is to be shown in the promo header
    private var promoHeaderPlan: PlanEntity? {
        let badgePresenter = SubscriptionOfferBadgePresenter()
        return discountedPlans
            .filter { !$0.isCurrentPlan(for: accountDetails) }
            .max { (badgePresenter.discountPercentage(for: $0) ?? 0) < (badgePresenter.discountPercentage(for: $1) ?? 0) }
    }
}
