import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct CurrentPlanView: View {
    private let currentPlan: CurrentPlan

    init(currentPlan: CurrentPlan) {
        self.currentPlan = currentPlan
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            labelRow
            QuotaProgressView(currentPlan.quota)
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .fill(TokenColors.Background.surface1.swiftUI)
        )
    }

    private var labelRow: some View {
        HStack(spacing: TokenSpacing._3) {
            Text(currentPlan.name)
                .font(.callout.weight(.semibold))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text("•")
                .font(.callout.weight(.semibold))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text(Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan)
                .font(.footnote.weight(.regular))
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }
}

#Preview("Storage — almost full") {
    CurrentPlanView(currentPlan: CurrentPlan(
        name: "Free",
        quota: QuotaProgress(
            status: .almostFull,
            usedBytes: 16 * 1_073_741_824,
            totalBytes: 20 * 1_073_741_824
        )
    ))
    .padding()
}

#Preview("Transfer — full") {
    CurrentPlanView(currentPlan: CurrentPlan(
        name: "Pro I",
        quota: QuotaProgress(
            status: .full,
            usedBytes: 2_199_023_255_552,
            totalBytes: 2_199_023_255_552
        )
    ))
    .padding()
}
