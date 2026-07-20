import MEGAL10n
import MEGAUIComponent

enum QuotaUsageStyle {
    case usedOfTotal
    case usedOnly
}

struct CurrentPlan: Equatable {
    let name: String
    let quota: QuotaProgress
}

struct RecommendedPlan: Equatable {
    let name: String
    let ribbonText: String
    let price: PlanPrice
    let storageText: String
    let transferText: String
    let quotaProgress: QuotaProgress
}

struct QuotaProgress: Equatable {
    let status: QuotaStatus
    let usedBytes: Int64
    let totalBytes: Int64
    let style: QuotaUsageStyle

    var usageText: String {
        switch style {
        case .usedOfTotal:
            let storageUsedString = String.memoryStyleString(fromByteCount: usedBytes).formattedByteCountString()
            let storageMaxString = String.memoryStyleString(fromByteCount: totalBytes).formattedByteCountString()
            return Strings.Localizable.Home.Widgets.AccountDetails.storageUsage(storageUsedString, storageMaxString)
        case .usedOnly:
            let storageUsedString = String.memoryStyleString(fromByteCount: usedBytes).formattedByteCountString()
            return Strings.Localizable.AccountMenu.BusinessAndProFlexiAccountsStorageUsed.title(storageUsedString)
        }
    }

    var usedPercentage: Int {
        guard totalBytes > 0 else { return 0 }
        return max(0, Int((Double(usedBytes) / Double(totalBytes) * 100).rounded()))
    }

    init(status: QuotaStatus, usedBytes: Int64, totalBytes: Int64, style: QuotaUsageStyle) {
        self.status = status
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.style = style
    }
}
