import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct QuotaProgressView: View {
    private let progress: QuotaProgress

    init(_ progress: QuotaProgress) {
        self.progress = progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            QuotaProgressBarView(status: progress.status, used: progress.usedBytes, total: progress.totalBytes)
            QuotaUsageView(progress.usageText)
        }
    }
}

#Preview {
    VStack(spacing: TokenSpacing._7) {
        QuotaProgressView(
            QuotaProgress(
                status: .almostFull,
                usedBytes: 16 * 1_073_741_824,
                totalBytes: 20 * 1_073_741_824,
                style: .usedOnly
            )
        )
        QuotaProgressView(
            QuotaProgress(
                status: .good,
                usedBytes: 19 * 1_073_741_824,
                totalBytes: 200 * 1_073_741_824,
                style: .usedOfTotal
            )
        )
        QuotaProgressView(
            QuotaProgress(
                status: .full,
                usedBytes: 1 * 1_073_741_824,
                totalBytes: 2 * 1_073_741_824,
                style: .usedOfTotal
            )
        )
    }
    .padding()
}
