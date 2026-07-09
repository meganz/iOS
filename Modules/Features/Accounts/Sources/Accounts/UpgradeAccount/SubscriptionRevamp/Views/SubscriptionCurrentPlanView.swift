import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct SubscriptionCurrentPlanView: View {
    private let viewModel: SubscriptionCurrentPlanViewModel

    init(viewModel: SubscriptionCurrentPlanViewModel) {
        self.viewModel = viewModel
    }

    init(
        plan: PlanEntity,
        status: SubscriptionCurrentPlanViewModel.Status? = nil,
        badgeTitle: String? = nil
    ) {
        self.init(viewModel: SubscriptionCurrentPlanViewModel(
            plan: plan,
            status: status,
            badgeTitle: badgeTitle
        ))
    }

    var body: some View {
        card
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            HStack(spacing: TokenSpacing._3) {
                Text(Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)

                if let badgeTitle = viewModel.badgeTitle {
                    MEGABadge(text: badgeTitle, type: .error, size: .regular, icon: nil)
                }
            }

            planLine

            if let status = viewModel.status, let statusText = viewModel.statusText {
                statusLine(for: status, text: statusText)
            }
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TokenColors.Background.surface1.swiftUI, in: RoundedRectangle(cornerRadius: TokenRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.medium)
                .stroke(TokenColors.Border.subtle.swiftUI, lineWidth: 1)
        )
    }

    private var planLine: some View {
        HStack {
            Text(viewModel.name)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            if let cycleText = viewModel.cycleText {
                Text("•")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                Text(cycleText)
                    .font(.caption)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
    }

    private func statusLine(for status: SubscriptionCurrentPlanViewModel.Status, text: String) -> some View {
        HStack(spacing: TokenSpacing._2) {
            statusIcon(for: status)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)

            Text(text)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private func statusIcon(for status: SubscriptionCurrentPlanViewModel.Status) -> Image {
        switch status {
        case .renews: MEGAAssets.Image.monoCalendar01SmallThinOutline
        case .expires: MEGAAssets.Image.hourglassNewestSmallRegularOutline
        }
    }
}

#Preview("Subscription") {
    SubscriptionCurrentPlanView(
        plan: PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly),
        status: .renews
    )
    .padding()
}

#Preview("One-off · expiring") {
    SubscriptionCurrentPlanView(
        plan: PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .none),
        status: .expires,
        badgeTitle: "Expiring",
    )
    .padding()
}

#Preview("Highest tier") {
    SubscriptionCurrentPlanView(
        plan: PlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .monthly),
        status: .renews,
    )
    .padding()
}
