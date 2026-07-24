import MEGAAppPresentation
import MEGADomain
import MEGAUIComponent

/// Resolves a plan's display `PlanPrice` via the domain pricing use case and the view-layer mapper.
///
/// Both introductory and promotional discounts flow through `SubscriptionPlanPriceUseCase`
/// (introductory takes priority when a plan carries both).
struct SubscriptionPlanPriceResolver {
    private let priceUseCase: any SubscriptionPlanPriceUseCaseProtocol
    private let mapper: RecommendedPlanPriceMapper

    init(
        priceUseCase: any SubscriptionPlanPriceUseCaseProtocol = SubscriptionPlanPriceUseCase(),
        mapper: RecommendedPlanPriceMapper = RecommendedPlanPriceMapper()
    ) {
        self.priceUseCase = priceUseCase
        self.mapper = mapper
    }

    func planPrice(for plan: PlanEntity) -> PlanPrice {
        mapper.map(priceUseCase.planPrice(for: plan))
    }
}
