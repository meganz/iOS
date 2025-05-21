import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct SubscriptionPurchaseFreePlanView: View {
    let getStartedButtonTapped: () -> Void

    var body: some View {
        VStack(spacing: TokenSpacing._3) {
            VStack(alignment: .leading, spacing: TokenSpacing._3) {
                Text(Strings.Localizable.SubscriptionPurchase.FreePlanCard.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                Text(Strings.Localizable.SubscriptionPurchase.FreePlanCard.description)
                    .font(.caption)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }

            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureCloud,
                title: Strings.Localizable.SubscriptionPurchase.FreePlanCard.Feature.one
            )

            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureTransfers,
                title: Strings.Localizable.SubscriptionPurchase.FreePlanCard.Feature.two
            )

            MEGAButton(
                Strings.Localizable.SubscriptionPurchase.FreePlanCard.Button.title,
                type: .secondary,
                action: getStartedButtonTapped
            )
            .padding(.vertical, 8)
        }
        .padding(TokenSpacing._5)
        .background(TokenColors.Background.page.swiftUI)
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.medium)
                .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 2)
        )
        .padding(.vertical, TokenSpacing._5)
    }
}
