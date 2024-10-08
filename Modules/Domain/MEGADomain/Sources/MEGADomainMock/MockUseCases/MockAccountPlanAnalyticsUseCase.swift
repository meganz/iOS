import MEGADomain

public final class MockAccountPlanAnalyticsUseCase: AccountPlanAnalyticsUseCaseProtocol {
    public var capturedPlan: AccountTypeEntity?
    public var sendAccountPlanTapStats_calledTimes = 0
    
    public init() {}
    
    public func sendAccountPlanTapStats(plan: AccountTypeEntity) {
        sendAccountPlanTapStats_calledTimes += 1
        capturedPlan = plan
    }
}
