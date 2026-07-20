import MEGAUIComponent
import SwiftUI

struct RecommendedPlanFooterView: View {
    let planName: String

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                // IOS-12210
                MEGAButton("Upgrade to \(planName)", type: .primary, action: {}),
                // IOS-12210
                MEGAButton("View all plans", type: .textOnly, action: {})
            ],
            allowMaxWidthForWideScreen: true
        )
    }
}

#Preview {
    RecommendedPlanFooterView(planName: "Essential")
}
