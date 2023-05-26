import MEGADomain
import SwiftUI

final class AccountPlanViewModel {
    let plan: AccountPlanEntity
    let planTag: AccountPlanTagEntity
    let isSelected: Bool
    let didTapPlan: () -> Void
    
    init(plan: AccountPlanEntity,
         planTag: AccountPlanTagEntity = AccountPlanTagEntity.none,
         isSelected: Bool,
         didTapPlan: @escaping () -> Void) {
        
        self.plan = plan
        self.planTag = planTag
        self.isSelected = isSelected
        self.didTapPlan = didTapPlan
    }
    
    var isCurrenPlan: Bool {
        planTag == .currentPlan
    }
}
