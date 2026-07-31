import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionProFeaturesView: View {

    private let viewModel: SubscriptionProFeaturesViewModel

    init(viewModel: SubscriptionProFeaturesViewModel) {
        self.viewModel = viewModel
    }

    private var features: [SubscriptionProFeature] {
        [
            SubscriptionProFeature(
                icon: MEGAAssets.Image.subscriptionFeatureCloud,
                title: Strings.Localizable.SubscriptionPurchase.Feature.Storage.description(viewModel.maxPlanStorage)
            ),
            SubscriptionProFeature(
                icon: MEGAAssets.Image.subscriptionFeatureTransfers,
                title: Strings.Localizable.SubscriptionPurchase.Feature.Transfer.description(viewModel.maxPlanTransfer)
            ),
            SubscriptionProFeature(
                icon: MEGAAssets.Image.subscriptionFeatureVPN,
                title: Strings.Localizable.SubscriptionPurchase.Feature.Vpn.description
            ),
            SubscriptionProFeature(
                icon: MEGAAssets.Image.subscriptionFeatureTransfersPWM,
                title: Strings.Localizable.SubscriptionPurchase.Feature.Pass.description
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            Text(Strings.Localizable.SubscriptionPurchase.Revamp.Features.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            VStack(alignment: .leading, spacing: TokenSpacing._2) {
                ForEach(features) { feature in
                    SubscriptionProFeatureRow(feature: feature)
                }
            }
        }
    }
}

private struct SubscriptionProFeatureRow: View {
    let feature: SubscriptionProFeature

    var body: some View {
        HStack(alignment: .center, spacing: TokenSpacing._3) {
            feature.icon
                .resizable()
                .frame(width: 24, height: 24)

            Text(feature.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, TokenSpacing._3)
    }
}

#Preview {
    SubscriptionProFeaturesView(viewModel: .init(plans: []))
        .padding()
}
