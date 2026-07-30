@testable import Accounts
import MEGADomain
import MEGADomainMock
import Testing

@Suite("PlanEntity.isCurrentPlan(for:)")
struct PlanEntityCurrentPlanTests {

    private func plan(_ type: AccountTypeEntity, _ cycle: SubscriptionCycleEntity) -> PlanEntity {
        PlanEntity(type: type, subscriptionCycle: cycle)
    }

    @Test("Is the current plan when both the level and the billing cycle match")
    func matchesSameLevelAndCycle() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        #expect(plan(.proI, .monthly).isCurrentPlan(for: details))
    }

    @Test("Is not the current plan when the billing cycle differs")
    func differentCycleIsNotCurrent() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        #expect(!plan(.proI, .monthly).isCurrentPlan(for: details))
    }

    @Test("Is not the current plan when the plan level differs")
    func differentLevelIsNotCurrent() {
        let details = AccountDetailsEntity.build(proLevel: .proII, subscriptionCycle: .monthly)
        #expect(!plan(.proI, .monthly).isCurrentPlan(for: details))
    }

    @Test("Is not the current plan for a free account with no billing cycle")
    func noCycleIsNotCurrent() {
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        #expect(!plan(.proI, .monthly).isCurrentPlan(for: details))
    }
}
