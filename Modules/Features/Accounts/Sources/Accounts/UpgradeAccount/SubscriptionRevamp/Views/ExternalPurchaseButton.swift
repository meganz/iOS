import MEGAUIComponent
import SwiftUI

/// The low-emphasis "buy on our website" button shown under a plan card's buy button.
///
/// Observes ``ExternalPurchaseViewModel`` so a website link request disables only these buttons, leaving the
/// in-app buy buttons usable.
struct ExternalPurchaseButton: View {
    @ObservedObject var viewModel: ExternalPurchaseViewModel
    let title: String
    let productIdentifier: String

    var body: some View {
        MEGAButton(title, type: .textOnly, state: state, action: buy)
    }

    private var state: MEGAButtonState {
        viewModel.isPurchasing ? .disabled : .default
    }

    private func buy() {
        Task { await viewModel.buy(productIdentifier: productIdentifier) }
    }
}
