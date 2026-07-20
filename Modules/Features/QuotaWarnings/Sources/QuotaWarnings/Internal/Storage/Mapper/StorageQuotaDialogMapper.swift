import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
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
            image: MEGAAssets.UIImage.storageAlmostFull,
            // IOS-12210
            title: "Your storage is \(progress.usedPercentage)% full",
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
            // IOS-12210
            "Upgrade your plan before you run out of space"
        case .full:
            // IOS-12210
            "Upgrade your plan to get more storage and upload more files"
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
