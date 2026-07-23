import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct RecommendedPlanView: View {
    private let plan: RecommendedPlan

    init(plan: RecommendedPlan) {
        self.plan = plan
    }

    var body: some View {
        PlanCardContainer {
            PlanCardRibbon(
                text: plan.ribbonText,
                fill: TokenColors.Button.brand.swiftUI,
                foreground: TokenColors.Text.onColor.swiftUI
            )
        } content: {
            VStack(alignment: .leading, spacing: TokenSpacing._5) {
                VStack(alignment: .leading, spacing: TokenSpacing._4) {
                    PlanTitleView(plan.name)
                    PlanPriceView(plan.price)
                    PlanFeatureListView {
                        PlanFeatureView(
                            icon: MEGAAssets.Image.subscriptionFeatureCloud,
                            text: plan.storageText
                        )
                        PlanFeatureView(
                            icon: MEGAAssets.Image.subscriptionFeatureTransfers,
                            text: plan.transferText
                        )
                    }
                }
                QuotaProgressView(plan.quotaProgress)
            }
        }
    }

}
