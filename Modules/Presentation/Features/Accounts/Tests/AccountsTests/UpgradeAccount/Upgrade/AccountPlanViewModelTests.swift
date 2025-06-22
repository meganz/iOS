@testable import Accounts
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import Testing

struct AccountPlanViewModelTests {
    @Suite("Plan Badge")
    struct PlanBadge {
        @Test
        @MainActor
        func currentPlan() {
            let sut = makeSUT(planTag: .currentPlan)
            #expect(sut.planBadge?.type == .warning)
            #expect(sut.planBadge?.text == Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan)
        }
        
        @Test
        @MainActor
        func recommended() {
            let sut = makeSUT(planTag: .recommended)
            #expect(sut.planBadge?.type == .infoPrimary)
            #expect(sut.planBadge?.text == Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended)
        }
        
        @Test
        @MainActor
        func none() {
            let sut = makeSUT(planTag: .none)
            #expect(sut.planBadge == nil)
        }
    }
    
    @MainActor
    private static func makeSUT(
        plan: PlanEntity = .init(),
        planTag: AccountPlanTagEntity = .none,
        isSelected: Bool = false,
        isSelectionEnabled: Bool = true,
        didTapPlan: @escaping () -> Void = {}
    ) -> AccountPlanViewModel {
        .init(
            plan: plan,
            planTag: planTag,
            isSelected: isSelected,
            isSelectionEnabled: isSelectionEnabled,
            didTapPlan: didTapPlan)
    }
}
