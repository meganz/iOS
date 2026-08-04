import MEGAUIComponent
import SwiftUI

/// The low-emphasis "buy on our website" button shown under a plan card's buy button.
struct ExternalPurchaseButton: View {
    let title: String

    var body: some View {
        MEGAButton(title, type: .textOnly, action: buy)
    }

    private func buy() {
        // [IOS-12353]: Open the external purchase page
    }
}
