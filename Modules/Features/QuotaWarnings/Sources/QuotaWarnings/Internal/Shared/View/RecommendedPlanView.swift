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

#Preview("Yearly") {
    RecommendedPlanView(plan: RecommendedPlan(
        name: "Essential",
        ribbonText: "Best for you",
        price: .yearly(price: "€3.33/month", billing: "€40.01 charged yearly"),
        storageText: "200 GB storage",
        transferText: "2 TB transfer",
        quotaProgress: QuotaProgress(status: .good, usedBytes: 19 * 1_073_741_824, totalBytes: 200 * 1_073_741_824, style: .usedOfTotal)
    ))
    .padding()
}

#Preview("Discount") {
    RecommendedPlanView(plan: RecommendedPlan(
        name: "Pro I",
        ribbonText: "Black Friday · 50% off",
        price: .discount(
            originalPrice: "€9.99",
            discountedPrice: "€4.99/month",
            description: "Discount price for the first 12 months"
        ),
        storageText: "2 TB storage",
        transferText: "2 TB transfer",
        quotaProgress: QuotaProgress(status: .good, usedBytes: 19 * 1_073_741_824, totalBytes: 2048 * 1_073_741_824, style: .usedOfTotal)
    ))
    .padding()
}
