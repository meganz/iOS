import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchaseFeaturesView: View {
    var body: some View {
        VStack(alignment: .leading) {
            SubscriptionPurchaseFeatureView(
                image: Image(.subscriptionFeatureCloud),
                title: Strings.Localizable.SubscriptionPurchase.Feature.One.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.One.description
            )

            SubscriptionPurchaseFeatureView(
                image: Image(.subscriptionFeatureTransfers),
                title: Strings.Localizable.SubscriptionPurchase.Feature.Two.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.Two.description
            )

            SubscriptionPurchaseFeatureView(
                image: Image(.subscriptionFeatureVPN),
                title: Strings.Localizable.SubscriptionPurchase.Feature.Three.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.Three.description
            )

            SubscriptionPurchaseFeatureView(
                image: Image(.subscriptionFeatureTransfersPWM),
                title: Strings.Localizable.SubscriptionPurchase.Feature.Four.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.Four.description,
            )
        }
        .padding(.bottom, TokenSpacing._8)
    }
}
