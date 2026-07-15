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
        price: .yearly(.init(pricePerMonth: "€3.33/month", billingCaption: "€40.01 charged yearly")),
        storageText: "200 GB storage",
        transferText: "2 TB transfer",
        quotaProgress: QuotaProgress(status: .good, usedBytes: 19 * 1_073_741_824, totalBytes: 200 * 1_073_741_824, style: .usedOfTotal)
    ))
    .padding()
}

#Preview("Monthly") {
    RecommendedPlanView(plan: RecommendedPlan(
        name: "Pro I",
        ribbonText: "Best for you",
        price: .monthly(.init(pricePerMonth: "€9.99/month")),
        storageText: "2 TB storage",
        transferText: "2 TB transfer",
        quotaProgress: QuotaProgress(status: .good, usedBytes: 19 * 1_073_741_824, totalBytes: 2048 * 1_073_741_824, style: .usedOfTotal)
    ))
    .padding()
}

#Preview("Discount monthly") {
    RecommendedPlanView(plan: RecommendedPlan(
        name: "Pro I",
        ribbonText: "Black Friday · 50% off",
        price: .discountMonthly(.init(
            originalPrice: "€9.99",
            discountedPrice: "€4.99/month",
            billingCaption: "Discount price for the first 12 months"
        )),
        storageText: "2 TB storage",
        transferText: "2 TB transfer",
        quotaProgress: QuotaProgress(status: .good, usedBytes: 19 * 1_073_741_824, totalBytes: 2048 * 1_073_741_824, style: .usedOfTotal)
    ))
    .padding()
}

#Preview("Discount yearly") {
    RecommendedPlanView(plan: RecommendedPlan(
        name: "Pro II",
        ribbonText: "Black Friday · 50% off",
        price: .discountYearly(.init(
            pricePerMonth: "€9.99/month",
            originalPrice: "€240",
            discountedPrice: "€119.88/year",
            billingCaption: "Billed at €119.88 for the first year, €240 charged yearly after"
        )),
        storageText: "10 TB storage",
        transferText: "10 TB transfer",
        quotaProgress: QuotaProgress(status: .good, usedBytes: 19 * 1_073_741_824, totalBytes: 10240 * 1_073_741_824, style: .usedOfTotal)
    ))
    .padding()
}
