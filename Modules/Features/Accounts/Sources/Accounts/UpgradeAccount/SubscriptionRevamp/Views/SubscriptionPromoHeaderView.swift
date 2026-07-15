import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct SubscriptionPromoHeaderView: View {
    private let model: SubscriptionPromoHeaderModel

    init(model: SubscriptionPromoHeaderModel) {
        self.model = model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MEGABadge(text: model.tag, type: .megaPrimary, size: .small, icon: nil)

            Text(model.title)
                .font(.title.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.vertical, TokenSpacing._4)

            Text(model.subtitle)
                .font(.title2.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.bottom, TokenSpacing._4)

            Text(model.validUntil)
                .font(.body)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(.bottom, TokenSpacing._2)

            SubscriptionCountdownTimerView(deadline: model.deadline)
                .padding(.top, TokenSpacing._2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Discount offer") {
    SubscriptionPromoHeaderView(
        model: SubscriptionPromoHeaderModel(
            tag: "Special offer",
            title: "Black Friday - 50% off",
            subtitle: "€119.88 for the first year",
            validUntil: "valid until July 11, 2026",
            deadline: .now.addingTimeInterval(60 * 60 * 24 * 28)
        )
    )
    .padding()
}

#Preview("Pay upfront") {
    SubscriptionPromoHeaderView(
        model: SubscriptionPromoHeaderModel(
            tag: "Special offer",
            title: "Flash Deal - 50% off",
            subtitle: "€29.94 of Pro I for 6 months",
            validUntil: "valid until July 11, 2026",
            deadline: .now.addingTimeInterval(60 * 60 * 24 * 28)
        )
    )
    .padding()
}
