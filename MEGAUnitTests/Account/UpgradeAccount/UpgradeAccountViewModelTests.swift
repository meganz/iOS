@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("Upgrade Account ViewModel Tests Suite - Verifies correct behavior for account plan analytics tracking.")
struct UpgradeAccountViewModelTests {
    
    // MARK: - Helper functions
    private static func makeSUT() -> (UpgradeAccountViewModel, MockAccountPlanAnalyticsUseCase) {
        let analyticsUseCase = MockAccountPlanAnalyticsUseCase()
        let sut = UpgradeAccountViewModel(accountPlanAnalyticsUsecase: analyticsUseCase)
        
        return (sut, analyticsUseCase)
    }
    
    // MARK: - Tests
    
    @Suite("Account Plan Tap Stats Tests")
    struct AccountPlanTapStatsTests {
        static let accountPlans: [AccountTypeEntity] = [.free, .lite, .proI, .proII, .proIII, .proFlexi, .starter, .basic, .essential, .business, .feature]
        
        @Test("Should send correct analytics event for each account plan type", arguments: accountPlans)
        func sendsCorrectAnalyticsEvent(for plan: AccountTypeEntity) {
            let (sut, analyticsUseCase) = makeSUT()
            sut.sendAccountPlanTapStats(plan.toMEGAAccountType())
            
            #expect(analyticsUseCase.sendAccountPlanTapStats_calledTimes == 1, "Expected sendAccountPlanTapStats to be called once.")
            #expect(analyticsUseCase.capturedPlan == plan, "Expected capturedPlan to be \(plan)")
        }
    }
}
