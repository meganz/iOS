import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchaseBenefitsView: View {
    let benefits: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            Text(Strings.Localizable.SubscriptionPurchase.FeaturesOfProPlan.title)
                .font(.subheadline.bold())
            
            BulletListView(items: benefits)
        }
    }
}

private struct BulletListView: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
