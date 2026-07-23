import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct SubscriptionCurrentPlanView: View {
    private let viewModel: SubscriptionCurrentPlanViewModel

    init(viewModel: SubscriptionCurrentPlanViewModel) {
        self.viewModel = viewModel
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
            .padding(.vertical, TokenSpacing._1)

            planLine
                .padding(.vertical, TokenSpacing._1)

            if let status = viewModel.status, let statusText = viewModel.statusText {
                statusLine(for: status, text: statusText)
            }
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TokenColors.Background.surface1.swiftUI, in: RoundedRectangle(cornerRadius: TokenRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 1)
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
