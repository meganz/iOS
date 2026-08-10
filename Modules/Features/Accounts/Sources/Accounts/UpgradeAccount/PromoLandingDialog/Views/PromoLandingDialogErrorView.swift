import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// Load failure state of the promotional offer landing dialog, offering a retry.
struct PromoLandingDialogErrorView: View {
    let dismissAction: @MainActor () -> Void
    let retryAction: @MainActor () async -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: TokenSpacing._7) {
                    message
                    MEGAButton(
                        Strings.Localizable.SubscriptionPurchase.Revamp.LoadError.Button.tryAgain,
                        type: .secondary,
                        action: { Task { await retryAction() } }
                    )
                    .fixedSize(horizontal: true, vertical: false)
                }
                .padding(TokenSpacing._5)
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
        .safeAreaInset(edge: .top, spacing: 0) {
            PromoLandingDialogCloseButton(dismissAction: dismissAction)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var message: some View {
        VStack(spacing: TokenSpacing._7) {
            MEGAAssets.Image.glassNoCloud
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            VStack(spacing: TokenSpacing._5) {
                Text(Strings.Localizable.SubscriptionPurchase.Revamp.Promo.LoadError.title)
                    .font(.title3.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Text(Strings.Localizable.SubscriptionPurchase.Revamp.Promo.LoadError.message)
                    .font(.callout)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PromoLandingDialogErrorView(dismissAction: {}, retryAction: {})
}
