import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct RecommendedPlanFooterView: View {
    let planName: String

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.QuotaWarning.RecommendedPlan.Button.upgradeToPlan(planName),
                    type: .primary,
                    action: {}
                ),
                MEGAButton(
                    Strings.Localizable.QuotaWarning.RecommendedPlan.Button.viewAllPlans,
                    type: .textOnly,
                    action: {}
                )
            ],
            allowMaxWidthForWideScreen: true
        )
    }
}

#Preview {
    RecommendedPlanFooterView(planName: "Essential")
}
