import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct PlanHeaderTagView: View {
    public var plan: PlanEntity
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
        case .currentPlan:
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan
        case .recommended:
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended
        case .introOffer:
            guard let percentage = plan.introDiscountPercentage else { return "" }
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.generalDeal("\(percentage)%")
        case .none:
            return ""
        }
    }
    
    private var planTagColor: Color {
        switch planTag {
        case .currentPlan: currentPlanTagColor
        case .recommended: recommendedPlanTagColor
        case .introOffer: TokenColors.Button.brand.swiftUI
        case .none: .clear
        }
    }
    
    private var planTagTextColor: Color {
        switch planTag {
        case .currentPlan: TokenColors.Text.warning.swiftUI
        case .recommended: TokenColors.Text.info.swiftUI
        case .introOffer: TokenColors.Text.onColor.swiftUI
        case .none: .clear
        }
    }
}
