import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

public struct PlanHeaderTagView: View {
    public var planTag: AccountPlanTagEntity
    public var currentPlanTagColor: Color
    public var recommendedPlanTagColor: Color
    
    public var body: some View {
        TagView(
            tagName: planTagName,
            tagColor: planTagColor,
            tagTextColor: planTagTextColor
        )
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
        case .recommended: recommendedPlanTagColor
        case .none: .clear
        }
    }
    
    private var planTagTextColor: Color {
        switch planTag {
        case .currentPlan: TokenColors.Text.warning.swiftUI
        case .recommended: TokenColors.Text.info.swiftUI
        case .none: .clear
        }
    }
}
