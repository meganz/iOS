import MEGAAppPresentation
import MEGADomain

@MainActor
public final class MockPlanPurchaseEligibilityChecking: PlanPurchaseEligibilityChecking {
    private let eligibilityResult: PlanPurchaseEligibility
    /// The eligibility reported once a cancellation has run; defaults to the initial one.
    private let refreshedEligibilityResult: PlanPurchaseEligibility
    private let cancelResult: Bool

    public private(set) var cancelActiveSubscription_calledCount = 0
    public private(set) var refreshedEligibility_calledCount = 0

    public init(
        eligibility: PlanPurchaseEligibility = .purchasable,
        refreshedEligibility: PlanPurchaseEligibility? = nil,
        cancelResult: Bool = true
    ) {
        self.eligibilityResult = eligibility
        self.refreshedEligibilityResult = refreshedEligibility ?? eligibility
        self.cancelResult = cancelResult
    }

    public func eligibility() -> PlanPurchaseEligibility {
        eligibilityResult
    }

    public func cancelActiveSubscription() async -> Bool {
        cancelActiveSubscription_calledCount += 1
        return cancelResult
    }

    public func refreshedEligibility() async -> PlanPurchaseEligibility {
        refreshedEligibility_calledCount += 1
        return refreshedEligibilityResult
    }
}
