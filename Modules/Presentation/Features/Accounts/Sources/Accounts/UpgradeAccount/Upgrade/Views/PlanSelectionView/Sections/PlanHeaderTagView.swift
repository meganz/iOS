import MEGADomain
import MEGAL10n
import SwiftUI

public struct PlanHeaderTagView: View {
    public var planTag: AccountPlanTagEntity
    public var currentPlanTagColor: Color
    public var recommededPlanTagColor: Color
    
    public var body: some View {
        Text(planTagName)
            .font(.caption2)
            .bold()
            .padding(6)
            .padding(.horizontal, 2)
            .background(planTagColor)
            .cornerRadius(10)
    }
    
    private var planTagName: String {
        switch planTag {
        case .currentPlan:
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan
        case .recommended:
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended
        case .none: return ""
        }
    }
    
    private var planTagColor: Color {
        switch planTag {
        case .currentPlan:
            return currentPlanTagColor
        case .recommended:
            return recommededPlanTagColor
        case .none:
            return .clear
        }
    }
}
