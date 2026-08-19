import MEGAAppPresentation
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct SignedOutPlanFooterView: View {
    let recommendedPlan: RecommendedPlan
    let trackingUseCase: any QuotaDialogTrackingUseCaseProtocol
    let onSignIn: @MainActor () -> Void

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.QuotaWarning.RecommendedPlan.Button.upgradeToPlan(recommendedPlan.name),
                    type: .primary,
                    action: {
                        onSignIn()
                        trackingUseCase.trackUpgradeTapped()
                    }
                ),
                MEGAButton(
                    Strings.Localizable.QuotaWarning.RecommendedPlan.Button.viewAllPlans,
                    type: .textOnly,
                    action: {
                        onSignIn()
                        trackingUseCase.trackViewAllPlansTapped()
                    }
                )
            ],
            allowMaxWidthForWideScreen: true
        )
    }
}

#if DEBUG
#Preview {
    SignedOutPlanFooterView(
        recommendedPlan: RecommendedPlan(
            productIdentifier: "preview.plan",
            name: "Essential",
            ribbonText: "Best for you",
            price: .yearly(.init(pricePerMonth: "€3.33/month", billingCaption: "€40.01 charged yearly")),
            storageText: "200 GB storage",
            transferText: "2 TB transfer",
            quotaProgress: nil
        ),
        trackingUseCase: QuotaDialogTrackingUseCase(
            kind: .transfer(.downloadExceeded),
            audience: .signedOut,
            tracker: NoOpAnalyticsTracker()
        ),
        onSignIn: {}
    )
}
#endif
