import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionProFeaturesView: View {
    private let features: [SubscriptionProFeature]

    init(features: [SubscriptionProFeature]) {
        self.features = features
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

struct SubscriptionProFeatureRow: View {
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
    SubscriptionProFeaturesView(
        features: [
            SubscriptionProFeature(icon: MEGAAssets.Image.subscriptionFeatureCloud, title: "Store up to 20 TB of data"),
            SubscriptionProFeature(icon: MEGAAssets.Image.subscriptionFeatureTransfers, title: "Enjoy up to 240 TB transfer quota"),
            SubscriptionProFeature(icon: MEGAAssets.Image.subscriptionFeatureVPN, title: "Stay safe online with MEGA VPN"),
            SubscriptionProFeature(icon: MEGAAssets.Image.subscriptionFeatureTransfersPWM, title: "Keep passwords safe with MEGA Pass")
        ]
    )
    .padding()
}
