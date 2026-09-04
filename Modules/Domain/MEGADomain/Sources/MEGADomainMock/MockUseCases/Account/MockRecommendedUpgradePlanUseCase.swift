import MEGADomain

public final class MockRecommendedUpgradePlanUseCase: RecommendedUpgradePlanUseCaseProtocol, @unchecked Sendable {
    private let recommendation: RecommendedUpgradePlanEntity?
    private let newAccountRecommendation: Result<RecommendedUpgradePlanEntity, any Error>?
    public private(set) var recommendCalled = 0
    public private(set) var recommendForNewAccountCalled = 0

    /// - Parameter newAccountRecommendation: what `recommendForNewAccount(from:)` answers. Defaults to
    /// mirroring `recommendation` — the plan when there is one, `noPlanToRecommend` when there is not.
    public init(
        recommendation: RecommendedUpgradePlanEntity? = nil,
        newAccountRecommendation: Result<RecommendedUpgradePlanEntity, any Error>? = nil
    ) {
        self.recommendation = recommendation
        self.newAccountRecommendation = newAccountRecommendation
    }

    public func recommend(
        for accountDetails: AccountDetailsEntity,
        from plans: [PlanEntity],
        cycleTarget: RecommendedPlanCycleTarget
    ) -> RecommendedUpgradePlanEntity? {
        recommendCalled += 1
        return recommendation
    }

    public func recommendForNewAccount(from plans: [PlanEntity]) throws -> RecommendedUpgradePlanEntity {
        recommendForNewAccountCalled += 1
        switch newAccountRecommendation {
        case let .success(plan):
            return plan
        case let .failure(error):
            throw error
        case nil:
            guard let recommendation else { throw RecommendedUpgradePlanError.noPlanToRecommend }
            return recommendation
        }
    }
}
