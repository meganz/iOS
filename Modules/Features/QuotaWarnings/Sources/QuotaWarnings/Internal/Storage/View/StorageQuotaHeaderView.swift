import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI

struct StorageQuotaHeaderView: View {
    private let quotaProgress: QuotaProgress
    private let severity: StorageQuotaSeverity
    
    init(severity: StorageQuotaSeverity, quotaProgress: QuotaProgress) {
        self.quotaProgress = quotaProgress
        self.severity = severity
    }

    private var title: String {
        // IOS-12210
        "Your storage is \(quotaProgress.usedPercentage)% full"
    }
    
    private var subtitle: String {
        switch severity {
        case .almostFull:
            // IOS-12210
            "Upgrade your plan before you run out of space"
        case .full:
            // IOS-12210
            "Upgrade your plan to get more storage and upload more files"
        }
    }
    
    var body: some View {
        VStack(spacing: TokenSpacing._5) {
            // IOS-12210
            Image(uiImage: MEGAAssets.UIImage.storageAlmostFull)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            VStack(spacing: TokenSpacing._3) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Text(subtitle)
                    .font(.callout.weight(.regular))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StorageQuotaHeaderView(
        severity: .almostFull,
        quotaProgress: QuotaProgress(status: .almostFull, usedBytes: 100, totalBytes: 10000, style: .usedOfTotal)
    )
    .padding()
}
