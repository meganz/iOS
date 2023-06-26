import MEGADomain
import SwiftUI

final class AccountPlanViewModel {
    let plan: AccountPlanEntity
    let planTag: AccountPlanTagEntity
    let isSelected: Bool
    let isSelectionEnabled: Bool
    let didTapPlan: () -> Void
    
    init(plan: AccountPlanEntity,
         planTag: AccountPlanTagEntity = AccountPlanTagEntity.none,
         isSelected: Bool,
         isSelectionEnabled: Bool,
         didTapPlan: @escaping () -> Void) {
        
        self.plan = plan
        self.planTag = planTag
        self.isSelected = isSelected
        self.isSelectionEnabled = isSelectionEnabled
        self.didTapPlan = didTapPlan
    }
}
