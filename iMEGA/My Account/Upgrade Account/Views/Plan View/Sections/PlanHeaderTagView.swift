import MEGADomain
import SwiftUI

struct PlanHeaderTagView: View {
    var planTag: AccountPlanTagEntity
    
    var body: some View {
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
            return Color(Colors.UpgradeAccount.Plan.currentPlan.color)
        case .recommended:
            return Color(Colors.UpgradeAccount.Plan.recommended.color)
        case .none:
            return .clear
        }
    }
}
