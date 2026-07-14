import MEGAAssets
import MEGADesignToken
import MEGAInfrastructure
import MEGAUIComponent
import SwiftUI

struct TransferQuotaHeaderView: View {
    private let quotaProgress: QuotaProgress
    private let severity: TransferQuotaSeverity
    private let isFreePlan: Bool
    
    init(
        severity: TransferQuotaSeverity,
        quotaProgress: QuotaProgress,
        isFreePlan: Bool
    ) {
        self.quotaProgress = quotaProgress
        self.severity = severity
        self.isFreePlan = isFreePlan
    }

    private var title: String {
        switch severity {
        case .limitedDownload:
            if isFreePlan {
                // IOS-12210
                "Your transfer quota is running low"
            } else {
                // IOS-12210
                "You've used \(quotaProgress.usedPercentage)% of your transfer quota"
            }
        case .downloadExceeded, .streamingExceeded:
            // IOS-12210
            "Transfer quota exceeded"
        }
    }

    private var subtitle: String {
        switch severity {
        case .limitedDownload:
            // IOS-12210
            "As a result, your download may be interrupted. Upgrade your plan to get more transfer quota. \(learnMoreTitle)"
        case .downloadExceeded:
            // IOS-12210
            "To continue your download, upgrade your plan to get more transfer quota. \(learnMoreTitle)"
        case .streamingExceeded:
            // IOS-12210
            "To continue media playback, upgrade your plan to get more transfer quota. \(learnMoreTitle)"
        }
    }

    // IOS-12210
    private let learnMoreTitle = "Learn more."
    
    private let learnMoreURL = URL(string: "https://help.mega.io/plans-storage/space-storage/transfer-quota")!
    
    var body: some View {
        VStack(spacing: TokenSpacing._5) {
            // IOS-12210
            Image(uiImage: MEGAAssets.UIImage.transferExceededQuota)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            VStack(spacing: TokenSpacing._3) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                subtitleView
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var subtitleView: some View {
        var container = AttributeContainer()
        container.underlineStyle = .single
        container.font = .callout.weight(.regular)
        container.foregroundColor = TokenColors.Text.primary.swiftUI
        
        return AttributedTextView(
            stringAttribute: .init(
                text: subtitle,
                font: .callout.weight(.regular),
                foregroundColor: TokenColors.Text.primary.swiftUI
            ),
            substringAttributeList: [
                .init(
                    text: learnMoreTitle,
                    attributes: container,
                    action: { DependencyInjection.externalLinkOpener.openExternalLink(with: learnMoreURL) }
                )
            ],
            textAlignment: .center
        )
    }
}

#Preview {
    TransferQuotaHeaderView(
        severity: .limitedDownload,
        quotaProgress: QuotaProgress(status: .almostFull, usedBytes: 100, totalBytes: 10000, style: .usedOfTotal),
        isFreePlan: true
    )
    
    TransferQuotaHeaderView(
        severity: .limitedDownload,
        quotaProgress: QuotaProgress(status: .almostFull, usedBytes: 100, totalBytes: 10000, style: .usedOfTotal),
        isFreePlan: false
    )
    
    TransferQuotaHeaderView(
        severity: .downloadExceeded,
        quotaProgress: QuotaProgress(status: .almostFull, usedBytes: 100, totalBytes: 10000, style: .usedOfTotal),
        isFreePlan: false
    )
    
    TransferQuotaHeaderView(
        severity: .streamingExceeded,
        quotaProgress: QuotaProgress(status: .almostFull, usedBytes: 100, totalBytes: 10000, style: .usedOfTotal),
        isFreePlan: false
    )
}
