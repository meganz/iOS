import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct RecommendedPlanFooterView: View {
    struct Dependency {
        let planPurchaser: any PlanPurchasing
    }

    let recommendedPlan: RecommendedPlan
    let onViewAllPlans: @MainActor () -> Void

    @StateObject private var purchaseViewModel: PlanPurchaseViewModel

    init(
        recommendedPlan: RecommendedPlan,
        dependency: RecommendedPlanFooterView.Dependency,
        onPurchased: @escaping @MainActor () -> Void,
        onViewAllPlans: @escaping @MainActor () -> Void
    ) {
        self.recommendedPlan = recommendedPlan
        self.onViewAllPlans = onViewAllPlans
        _purchaseViewModel = StateObject(
            wrappedValue: PlanPurchaseViewModel(
                planPurchaser: dependency.planPurchaser,
                onPurchased: onPurchased
            )
        )
    }

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.QuotaWarning.RecommendedPlan.Button.upgradeToPlan(recommendedPlan.name),
                    type: .primary,
                    action: {
                        Task { await purchaseViewModel.purchase(productIdentifier: recommendedPlan.productIdentifier) }
                    }
                ),
                MEGAButton(
                    Strings.Localizable.QuotaWarning.RecommendedPlan.Button.viewAllPlans,
                    type: .textOnly,
                    action: onViewAllPlans
                )
            ],
            allowMaxWidthForWideScreen: true
        )
        .disabled(purchaseViewModel.isPurchasing)
        .planPurchaseAlert(purchaseViewModel)
    }
}

#if DEBUG
#Preview {
    RecommendedPlanFooterView(
        recommendedPlan: RecommendedPlan(
            productIdentifier: "preview.plan",
            name: "Essential",
            ribbonText: "Best for you",
            price: .yearly(.init(pricePerMonth: "€3.33/month", billingCaption: "€40.01 charged yearly")),
            storageText: "200 GB storage",
            transferText: "2 TB transfer",
            quotaProgress: QuotaProgress(status: .good, usedBytes: 0, totalBytes: 1, style: .usedOfTotal)
        ),
        dependency: .init(planPurchaser: PreviewPlanPurchasing()),
        onPurchased: {},
        onViewAllPlans: {}
    )
}
#endif
