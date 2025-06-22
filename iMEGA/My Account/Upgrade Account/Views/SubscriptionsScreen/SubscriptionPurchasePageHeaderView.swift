import SwiftUI

struct SubscriptionPurchasePageHeaderView: View {
    @Binding var hideHeaderBackground: Bool
    let showBackButton: Bool
    let dismissAction: () -> Void

    var body: some View {
        SubscriptionPurchaseHeaderView(
            showBackButton: showBackButton,
            dismissAction: dismissAction
        )
        .background {
            if !hideHeaderBackground {
                backgroundBlurView
            }
        }
    }

    private var backgroundBlurView: some View {
        VStack(spacing: 0) {
            Color
                .clear
                .background(Material.regular)
            Divider()
        }
    }
}
