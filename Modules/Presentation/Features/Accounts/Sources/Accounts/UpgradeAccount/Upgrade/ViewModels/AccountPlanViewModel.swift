import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import SwiftUI

@MainActor
public final class AccountPlanViewModel {
    public let plan: PlanEntity
    public let planTag: AccountPlanTagEntity
    public let isSelected: Bool
    public let isSelectionEnabled: Bool
    public let didTapPlan: () -> Void
    
    public var planBadge: PlanBadge? {
        switch planTag {
        case .currentPlan: PlanBadge.currentPlan
        case .recommended: PlanBadge.recommended
        case .none: nil
        }
    }
    
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
