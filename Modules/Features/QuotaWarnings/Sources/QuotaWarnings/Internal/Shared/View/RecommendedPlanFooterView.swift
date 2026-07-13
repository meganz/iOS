import MEGADomain
import MEGAUIComponent
import SwiftUI

struct RecommendedPlanFooterView: View {
    let plan: PlanEntity

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                // IOS-12210
                MEGAButton("Upgrade to \(plan.name)", type: .primary, action: {}),
                // IOS-12210
                MEGAButton("View all plans", type: .textOnly, action: {})
            ],
            allowMaxWidthForWideScreen: true
        )
    }
}

#Preview {
    RecommendedPlanFooterView(plan: .mockEssentialYearly)
}
