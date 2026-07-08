import MEGADesignToken
import SwiftUI

struct SubscriptionCountdownTimerView: View {
    private let deadline: Date
    private let daysLabel: String
    private let hoursLabel: String
    private let minutesLabel: String

    init(
        deadline: Date,
        daysLabel: String,
        hoursLabel: String,
        minutesLabel: String
    ) {
        self.deadline = deadline
        self.daysLabel = daysLabel
        self.hoursLabel = hoursLabel
        self.minutesLabel = minutesLabel
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let countdown = SubscriptionCountdown.remaining(until: deadline, from: context.date)

            HStack(spacing: 0) {
                unit(value: countdown.days, label: daysLabel)
                divider
                unit(value: countdown.hours, label: hoursLabel)
                divider
                unit(value: countdown.minutes, label: minutesLabel)
            }
            .padding(.vertical, TokenSpacing._4)
            .frame(maxWidth: .infinity)
            .background(TokenColors.Brand.containerDefault.swiftUI, in: RoundedRectangle(cornerRadius: TokenRadius.medium))
        }
    }

    private func unit(value: Int, label: String) -> some View {
        VStack(spacing: TokenSpacing._1) {
            Text(String(format: "%02d", value))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(TokenColors.Border.strong.swiftUI)
            .frame(width: 1, height: 32)
    }
}

#Preview {
    SubscriptionCountdownTimerView(
        deadline: .now.addingTimeInterval(60 * 60 * 24 * 28),
        daysLabel: "Days",
        hoursLabel: "Hours",
        minutesLabel: "Minutes"
    )
    .padding()
}
