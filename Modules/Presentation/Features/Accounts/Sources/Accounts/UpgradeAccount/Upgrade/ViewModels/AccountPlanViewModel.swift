import MEGADomain
import SwiftUI

public final class AccountPlanViewModel {
    public let plan: PlanEntity
    public let planTag: AccountPlanTagEntity
    public let isSelected: Bool
    public let isSelectionEnabled: Bool
    public let didTapPlan: () -> Void
    
    public init(
        plan: PlanEntity,
        planTag: AccountPlanTagEntity = AccountPlanTagEntity.none,
        isSelected: Bool,
        isSelectionEnabled: Bool,
        didTapPlan: @escaping () -> Void
    ) {
        self.plan = plan
        self.planTag = planTag
        self.isSelected = isSelected
        self.isSelectionEnabled = isSelectionEnabled
        self.didTapPlan = didTapPlan
    }
}
