import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchaseFeaturesView: View {
    let maxPlanStorage: String
    
    var body: some View {
        VStack(alignment: .leading) {
            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureCloud,
                title: Strings.Localizable.SubscriptionPurchase.Feature.One.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.Storage.description(maxPlanStorage)
            )

            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureTransfers,
                title: Strings.Localizable.SubscriptionPurchase.Feature.Two.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.Two.description
            )

            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureVPN,
                title: Strings.Localizable.SubscriptionPurchase.Feature.Three.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.Three.description
            )

            SubscriptionPurchaseFeatureView(
                image: MEGAAssets.Image.subscriptionFeatureTransfersPWM,
                title: Strings.Localizable.SubscriptionPurchase.Feature.Four.title,
                description: Strings.Localizable.SubscriptionPurchase.Feature.Four.description,
            )
        }
        .padding(.bottom, TokenSpacing._8)
    }
}
