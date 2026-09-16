import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct PromoLandingDialogFooterView: View {
    let title: String
    let productIdentifier: String
    let isOfferExpired: Bool
    let isSideBySide: Bool
    let viewAllPlans: PromoLandingDialogContentViewModel.ViewAllPlans

    @StateObject private var purchaseViewModel: PlanPurchaseViewModel

    init(
        title: String,
        productIdentifier: String,
        isOfferExpired: Bool,
        isSideBySide: Bool,
        planPurchaser: some PlanPurchasing,
        purchaseTracker: some PlanPurchaseTracking,
        onPurchased: @escaping @MainActor () -> Void,
        viewAllPlans: PromoLandingDialogContentViewModel.ViewAllPlans
    ) {
        self.title = title
        self.productIdentifier = productIdentifier
        self.isOfferExpired = isOfferExpired
        self.isSideBySide = isSideBySide
        self.viewAllPlans = viewAllPlans
        _purchaseViewModel = StateObject(
            wrappedValue: PlanPurchaseViewModel(
                planPurchaser: planPurchaser,
                onPurchased: onPurchased,
                tracker: purchaseTracker
            )
        )
    }

    var body: some View {
        VStack(spacing: TokenSpacing._5) {
            if !isOfferExpired {
                PlanPurchaseButton(
                    purchaseViewModel: purchaseViewModel,
                    title: title,
                    productIdentifier: productIdentifier,
                    style: .brand
                )
            }
            viewAllPlansButton
        }
        .if(!isSideBySide) { $0.maxWidthForWideScreen() }
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
                type: isOfferExpired ? .primary : .textOnly,
                state: purchaseViewModel.isPurchasing ? .disabled : .default,
                action: { action() }
            )
        }
    }
}
