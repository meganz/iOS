import MEGADomain

public final class MockAccountSubscriptionValidationUseCase: AccountSubscriptionValidationUseCaseProtocol, @unchecked Sendable {
    private let eligibilityResult: PlanPurchaseEligibility
    public private(set) var eligibilityCalledCount = 0

    public init(eligibility: PlanPurchaseEligibility = .purchasable) {
        eligibilityResult = eligibility
    }

    public func eligibility(for accountDetails: AccountDetailsEntity) -> PlanPurchaseEligibility {
        eligibilityCalledCount += 1
        return eligibilityResult
    }
}
