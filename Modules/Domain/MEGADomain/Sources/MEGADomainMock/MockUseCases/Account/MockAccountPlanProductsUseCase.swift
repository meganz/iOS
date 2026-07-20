import MEGADomain

public final class MockAccountPlanProductsUseCase: AccountPlanProductsUseCaseProtocol, @unchecked Sendable {
    private let plans: [PlanEntity]
    public private(set) var availablePlansCalled = 0

    public init(plans: [PlanEntity] = []) {
        self.plans = plans
    }

    public func availablePlans() async -> [PlanEntity] {
        availablePlansCalled += 1
        return plans
    }
}
