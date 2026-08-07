import MEGAAppPresentation
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct PromoLandingDialogFooterView: View {
    let title: String
    let productIdentifier: String

    @StateObject private var purchaseViewModel: PlanPurchaseViewModel

    init(
        title: String,
        productIdentifier: String,
        planPurchaser: some PlanPurchasing,
        onPurchased: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.productIdentifier = productIdentifier
        _purchaseViewModel = StateObject(
            wrappedValue: PlanPurchaseViewModel(
                planPurchaser: planPurchaser,
                onPurchased: onPurchased
            )
        )
    }

    var body: some View {
        PlanPurchaseButton(
            purchaseViewModel: purchaseViewModel,
            title: title,
            productIdentifier: productIdentifier,
            style: .brand
        )
        .maxWidthForWideScreen()
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._7)
        .frame(maxWidth: .infinity)
        .background(TokenColors.Background.page.swiftUI)
        .border(width: 0.5, edges: .top, color: TokenColors.Border.strong.swiftUI)
        .planPurchaseAlert(purchaseViewModel)
    }
}
