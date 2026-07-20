import MEGADomain

public final class MockRecommendedUpgradePlanUseCase: RecommendedUpgradePlanUseCaseProtocol, @unchecked Sendable {
    private let recommendation: RecommendedUpgradePlanEntity?
    public private(set) var recommendCalled = 0

    public init(recommendation: RecommendedUpgradePlanEntity? = nil) {
        self.recommendation = recommendation
    }

    public func recommend(
        for accountDetails: AccountDetailsEntity,
        from plans: [PlanEntity]
    ) -> RecommendedUpgradePlanEntity? {
        recommendCalled += 1
        return recommendation
    }
}
