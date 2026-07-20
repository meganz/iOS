import Foundation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGAUIComponent

struct TransferQuotaDialogMapper: QuotaDialogMapping {
    private let severity: TransferQuotaSeverity

    private let learnMoreTitle = Strings.Localizable.learnMore
    private let learnMoreURL = URL(string: "https://help.mega.io/plans-storage/space-storage/transfer-quota")!

    init(severity: TransferQuotaSeverity) {
        self.severity = severity
    }

    func header(accountDetails: AccountDetailsEntity) -> QuotaDialogHeader {
        .transfer(TransferQuotaHeader(
            image: MEGAAssets.Image.quotaWarning,
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
                Strings.Localizable.QuotaWarning.Transfer.RunningLow.title
            } else {
                Strings.Localizable.QuotaWarning.Transfer.PercentUsed.title(
                    currentQuotaProgress(accountDetails: accountDetails).usedPercentage
                )
            }
        case .downloadExceeded, .streamingExceeded:
            Strings.Localizable.QuotaWarning.Transfer.Exceeded.title
        }
    }

    private var subtitle: String {
        switch severity {
        case .limitedDownload:
            Strings.Localizable.QuotaWarning.Transfer.LimitedDownload.subtitle(learnMoreTitle)
        case .downloadExceeded:
            Strings.Localizable.QuotaWarning.Transfer.DownloadExceeded.subtitle(learnMoreTitle)
        case .streamingExceeded:
            Strings.Localizable.QuotaWarning.Transfer.StreamingExceeded.subtitle(learnMoreTitle)
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
