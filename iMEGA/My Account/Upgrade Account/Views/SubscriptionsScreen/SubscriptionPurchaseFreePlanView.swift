import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct SubscriptionPurchaseFreePlanView: View {
    let viewModel: SubscriptionPurchaseFreePlanViewModel
    let freeButtonTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            VStack(alignment: .leading, spacing: TokenSpacing._3) {
                Text(viewModel.cardTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                if viewModel.showDescription {
                    Text(Strings.Localizable.SubscriptionPurchase.FreePlanCard.description)
                        .font(.caption)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                }
            }

            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureCloud,
                title: viewModel.storageTile
            )

            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureTransfers,
                title: Strings.Localizable.SubscriptionPurchase.FreePlanCard.Feature.two
            )

            MEGAButton(
                viewModel.primaryButtonTitle,
                type: .secondary,
                action: freeButtonTapped
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
