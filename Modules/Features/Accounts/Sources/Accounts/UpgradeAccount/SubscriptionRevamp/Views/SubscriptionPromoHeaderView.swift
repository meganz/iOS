import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct SubscriptionPromoHeaderView: View {
    private let model: SubscriptionPromoHeaderModel
    private let daysLabel: String
    private let hoursLabel: String
    private let minutesLabel: String

    init(
        model: SubscriptionPromoHeaderModel,
        daysLabel: String,
        hoursLabel: String,
        minutesLabel: String
    ) {
        self.model = model
        self.daysLabel = daysLabel
        self.hoursLabel = hoursLabel
        self.minutesLabel = minutesLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            MEGABadge(text: model.tag, type: .megaPrimary, size: .small, icon: nil)

            Text(model.title)
                .font(.title.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Text(model.subtitle)
                .font(.title2.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Text(model.validUntil)
                .font(.body)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)

            SubscriptionCountdownTimerView(
                deadline: model.deadline,
                daysLabel: daysLabel,
                hoursLabel: hoursLabel,
                minutesLabel: minutesLabel
            )
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
        ),
        daysLabel: "Days",
        hoursLabel: "Hours",
        minutesLabel: "Minutes"
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
        ),
        daysLabel: "Days",
        hoursLabel: "Hours",
        minutesLabel: "Minutes"
    )
    .padding()
}
