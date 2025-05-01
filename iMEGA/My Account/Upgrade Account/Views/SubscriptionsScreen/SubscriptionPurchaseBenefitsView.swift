import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchaseBenefitsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            Text(Strings.Localizable.SubscriptionPurchase.FeaturesOfProPlan.title)
                .font(.subheadline.bold())

            Text(Strings.Localizable.SubscriptionPurchase.FeaturesOfProPlan.message)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
