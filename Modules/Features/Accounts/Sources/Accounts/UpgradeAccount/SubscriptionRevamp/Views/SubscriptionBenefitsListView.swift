import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionBenefitsListView: View {
    private let benefits: [String]

    init(benefits: [String]) {
        self.benefits = benefits
    }

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
            ForEach(Array(items.enumerated()), id: \.offset) { item in
                HStack(alignment: .top, spacing: TokenSpacing._2) {
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)

                    Text(item.element)
                        .font(.subheadline)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    SubscriptionBenefitsListView(
        benefits: [
            "Password-protected links",
            "Links with expiry dates",
            "Rewind up to 180 days of deleted data",
            "Priority support"
        ]
    )
    .padding()
}
