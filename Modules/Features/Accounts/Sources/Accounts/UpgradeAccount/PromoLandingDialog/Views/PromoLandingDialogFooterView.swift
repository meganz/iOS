import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct PromoLandingDialogFooterView: View {
    let title: String
    let productIdentifier: String
    let viewAllPlans: PromoLandingDialogContentView.Dependency.ViewAllPlans

    @StateObject private var purchaseViewModel: PlanPurchaseViewModel

    init(
        title: String,
        productIdentifier: String,
        planPurchaser: some PlanPurchasing,
        onPurchased: @escaping @MainActor () -> Void,
        viewAllPlans: PromoLandingDialogContentView.Dependency.ViewAllPlans
    ) {
        self.title = title
        self.productIdentifier = productIdentifier
        self.viewAllPlans = viewAllPlans
        _purchaseViewModel = StateObject(
            wrappedValue: PlanPurchaseViewModel(
                planPurchaser: planPurchaser,
                onPurchased: onPurchased
            )
        )
    }

    var body: some View {
        VStack(spacing: TokenSpacing._5) {
            PlanPurchaseButton(
                purchaseViewModel: purchaseViewModel,
                title: title,
                productIdentifier: productIdentifier,
                style: .brand
            )
            viewAllPlansButton
        }
        .maxWidthForWideScreen()
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._7)
        .frame(maxWidth: .infinity)
        .background(TokenColors.Background.page.swiftUI)
        .border(width: 0.5, edges: .top, color: TokenColors.Border.strong.swiftUI)
        .planPurchaseAlert(purchaseViewModel)
    }

    @ViewBuilder
    private var viewAllPlansButton: some View {
        if case .shown(let action) = viewAllPlans {
            MEGAButton(
                Strings.Localizable.QuotaWarning.RecommendedPlan.Button.viewAllPlans,
                type: .textOnly,
                state: purchaseViewModel.isPurchasing ? .disabled : .default,
                action: {
                    // [IOS-12242]: Handle analytics tracking
                    action()
                }
            )
        }
    }
}
