import MEGAAppPresentation
import MEGAUIComponent
import SwiftUI

/// A buy button that starts a purchase and reflects the in-flight state.
///
/// The only view on either subscription page that observes ``PlanPurchaseViewModel``, so a
/// purchase state change invalidates the buttons rather than the whole page. Both button
/// styles live here because the plan cards pick between them per card.
struct PlanPurchaseButton: View {
    enum Style {
        case brand
        case mega(MEGAButtonType)
    }

    @ObservedObject var purchaseViewModel: PlanPurchaseViewModel
    let title: String
    let productIdentifier: String
    let style: Style

    var body: some View {
        switch style {
        case .brand:
            BrandButton(title: title, state: state, accessibilityIdentifier: title, action: buy)
        case .mega(let type):
            MEGAButton(title, type: type, state: state, action: buy)
        }
    }

    private var state: MEGAButtonState {
        purchaseViewModel.isPurchasing ? .disabled : .default
    }

    private func buy() {
        Task { await purchaseViewModel.purchase(productIdentifier: productIdentifier) }
    }
}
