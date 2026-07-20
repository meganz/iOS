#if DEBUG || QA_CONFIG
import MEGADomain

/// A `QuotaDialogUseCaseProtocol` backed by explicit, in-memory values, for the QA dialog simulator.
///
/// Two modes:
/// - **`plan:`** — renders against a fixed, hand-picked `PlanEntity` (pass `nil` for the "no upgrade" state).
///   Bypasses the recommendation logic; used to pixel-check a specific card.
/// - **`catalog:`** — runs the **real** `RecommendedUpgradePlanUseCase` over the given catalog + account, so QA
///   exercises the actual selection rules (next-tier, discount override, no-upgrade, …).
public struct QAQuotaDialogUseCase: QuotaDialogUseCaseProtocol {
    private enum Source {
        case fixed(PlanEntity?)
        case recommend([PlanEntity])
    }

    private let account: AccountDetailsEntity
    private let source: Source

    /// Manual mode — render the given plan (or the no-upgrade state when `nil`).
    public init(accountDetails: AccountDetailsEntity, plan: PlanEntity?) {
        self.account = accountDetails
        self.source = .fixed(plan)
    }

    /// Logic mode — run `RecommendedUpgradePlanUseCase` over `catalog` and render whatever it picks.
    public init(accountDetails: AccountDetailsEntity, catalog: [PlanEntity]) {
        self.account = accountDetails
        self.source = .recommend(catalog)
    }

    func upgradeOption() async throws -> QuotaUpgradeOption {
        switch source {
        case let .fixed(plan):
            if let plan {
                .available(accountDetails: account, recommendedPlan: RecommendedUpgradePlanEntity(plan: plan))
            } else {
                .unavailable(accountDetails: account)
            }
        case let .recommend(catalog):
            if let recommendedPlan = recommend(from: catalog) {
                .available(accountDetails: account, recommendedPlan: recommendedPlan)
            } else {
                .unavailable(accountDetails: account)
            }
        }
    }

    private func recommend(from catalog: [PlanEntity]) -> RecommendedUpgradePlanEntity? {
        RecommendedUpgradePlanUseCase(subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase())
            .recommend(for: account, from: catalog)
    }
}
#endif
