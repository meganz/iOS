import Foundation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGASwift
import MEGAUIComponent

struct TransferQuotaDialogMapper: QuotaDialogMapping {
    private let severity: TransferQuotaSeverity

    // IOS-12210
    private let learnMoreTitle = "Learn more."
    private let learnMoreURL = URL(string: "https://help.mega.io/plans-storage/space-storage/transfer-quota")!

    init(severity: TransferQuotaSeverity) {
        self.severity = severity
    }

    func header(accountDetails: AccountDetailsEntity) -> QuotaDialogHeader {
        .transfer(TransferQuotaHeader(
            image: MEGAAssets.UIImage.transferExceededQuota,
            title: title(accountDetails: accountDetails),
            subtitle: subtitle,
            learnMore: .init(text: learnMoreTitle, url: learnMoreURL)
        ))
    }

    func currentPlan(accountDetails: AccountDetailsEntity) -> CurrentPlan {
        CurrentPlan(
            name: accountDetails.proLevel.toAccountTypeDisplayName(),
            quota: currentQuotaProgress(accountDetails: accountDetails)
        )
    }

    func recommendedPlan(_ plan: RecommendedUpgradePlanEntity, accountDetails: AccountDetailsEntity) -> RecommendedPlan {
        let quotaProgress = QuotaProgress(
            status: .good,
            usedBytes: accountDetails.transferUsed,
            totalBytes: plan.transferLimit.gigabytesToBytes(),
            style: .usedOfTotal
        )
        return makeRecommendedPlan(plan, quotaProgress: quotaProgress)
    }

    // MARK: - Private

    private func title(accountDetails: AccountDetailsEntity) -> String {
        switch severity {
        case .limitedDownload:
            if accountDetails.isFree {
                // IOS-12210
                "Your transfer quota is running low"
            } else {
                // IOS-12210
                "You've used \(currentQuotaProgress(accountDetails: accountDetails).usedPercentage)% of your transfer quota"
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

    private func currentQuotaProgress(accountDetails: AccountDetailsEntity) -> QuotaProgress {
        let status: QuotaStatus = switch severity {
        case .limitedDownload: .almostFull
        case .downloadExceeded, .streamingExceeded: .full
        }

        return QuotaProgress(
            status: status,
            usedBytes: accountDetails.transferUsed,
            totalBytes: accountDetails.transferMax,
            style: accountDetails.proLevel == .free ? .usedOnly : .usedOfTotal
        )
    }
}
