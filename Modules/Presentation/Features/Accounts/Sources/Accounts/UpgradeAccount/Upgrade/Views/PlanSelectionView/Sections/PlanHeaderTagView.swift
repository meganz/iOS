import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI

public struct PlanHeaderTagView: View {
    public var planTag: AccountPlanTagEntity
    public var currentPlanTagColor: Color
    public var recommededPlanTagColor: Color
    
    public var body: some View {
        Text(planTagName)
            .font(.caption2)
            .bold()
            .foregroundStyle(planTagTextColor)
            .padding(6)
            .padding(.horizontal, 2)
            .background(planTagColor)
            .cornerRadius(10)
    }
    
    private var planTagName: String {
        switch planTag {
        case .currentPlan: Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan
        case .recommended: Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended
        case .none: ""
        }
    }
    
    private var planTagColor: Color {
        switch planTag {
        case .currentPlan: currentPlanTagColor
        case .recommended: recommededPlanTagColor
        case .none: .clear
        }
    }
    
    private var planTagTextColor: Color {
        switch planTag {
        case .currentPlan: isDesignTokenEnabled ? TokenColors.Text.warning.swiftUI : .primary
        case .recommended: isDesignTokenEnabled ? TokenColors.Text.info.swiftUI : .primary
        case .none: .clear
        }
    }
}
