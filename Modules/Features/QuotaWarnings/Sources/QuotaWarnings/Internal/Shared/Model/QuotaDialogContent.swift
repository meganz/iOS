import MEGAL10n
import MEGAUIComponent

struct CurrentPlan: Equatable {
    let name: String
    let quota: QuotaProgress
}

struct RecommendedPlan: Equatable {
    /// StoreKit product identifier, forwarded to the purchase port when the user taps Upgrade.
    let productIdentifier: String
    let name: String
    let ribbonText: String
    let price: PlanPrice
    let storageText: String
    let transferText: String
    /// `nil` for a free or signed-out user on the transfer dialog
    let quotaProgress: QuotaProgress?
}

struct QuotaProgress: Equatable {
    let status: QuotaStatus
    let usedBytes: Int64
    let totalBytes: Int64

    var usageText: String {
        let storageUsedString = String.memoryStyleString(fromByteCount: usedBytes).formattedByteCountString()
        let storageMaxString = String.memoryStyleString(fromByteCount: totalBytes).formattedByteCountString()
        return Strings.Localizable.Home.Widgets.AccountDetails.storageUsage(storageUsedString, storageMaxString)
    }

    var usedPercentage: Int {
        guard totalBytes > 0 else { return 0 }
        return max(0, Int((Double(usedBytes) / Double(totalBytes) * 100).rounded()))
    }
}
