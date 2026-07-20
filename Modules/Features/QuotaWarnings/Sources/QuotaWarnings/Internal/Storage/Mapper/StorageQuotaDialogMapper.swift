import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGAUIComponent

struct StorageQuotaDialogMapper: QuotaDialogMapping {
    private let severity: StorageQuotaSeverity

    init(severity: StorageQuotaSeverity) {
        self.severity = severity
    }

    func header(accountDetails: AccountDetailsEntity) -> QuotaDialogHeader {
        let progress = currentQuotaProgress(accountDetails: accountDetails)
        return .storage(StorageQuotaHeader(
            image: MEGAAssets.Image.quotaWarning,
            title: Strings.Localizable.QuotaWarning.Storage.title(progress.usedPercentage),
            subtitle: subtitle
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
            usedBytes: accountDetails.storageUsed,
            totalBytes: plan.storageLimit.gigabytesToBytes(),
            style: .usedOfTotal
        )
        return makeRecommendedPlan(plan, quotaProgress: quotaProgress)
    }

    // MARK: - Private

    private var subtitle: String {
        switch severity {
        case .almostFull:
            Strings.Localizable.QuotaWarning.Storage.AlmostFull.subtitle
        case .full:
            Strings.Localizable.QuotaWarning.Storage.Full.subtitle
        }
    }

    private func currentQuotaProgress(accountDetails: AccountDetailsEntity) -> QuotaProgress {
        let status: QuotaStatus = switch severity {
        case .almostFull: .almostFull
        case .full: .full
        }

        return QuotaProgress(
            status: status,
            usedBytes: accountDetails.storageUsed,
            totalBytes: accountDetails.storageMax,
            style: .usedOfTotal
        )
    }
}
