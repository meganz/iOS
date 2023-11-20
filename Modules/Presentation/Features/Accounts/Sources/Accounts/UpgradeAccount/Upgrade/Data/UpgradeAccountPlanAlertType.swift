import MEGAL10n

public enum UpgradeAccountPlanAlertType {
    case restore(_ status: AlertStatus)
    case purchase(_ status: AlertStatus)
    
    public enum AlertStatus {
        case success, incomplete, failed
    }
    
    public var title: String {
        switch self {
        case .restore(let status):
            switch status {
            case .success: return Strings.Localizable.thankYouTitle
            case .incomplete: return Strings.Localizable.incompleteRestoreTitle
            case .failed: return Strings.Localizable.failedRestoreTitle
            }
        case .purchase(let status):
            switch status {
            case .failed: return Strings.Localizable.failedPurchaseTitle
            default: return ""
            }
        }
    }
    
    public var message: String {
        switch self {
        case .restore(let status):
            switch status {
            case .success: return Strings.Localizable.purchaseRestoreMessage
            case .incomplete: return Strings.Localizable.incompleteRestoreMessage
            case .failed: return Strings.Localizable.failedRestoreMessage
            }
        case .purchase(let status):
            switch status {
            case .failed: return Strings.Localizable.failedPurchaseMessage
            default: return ""
            }
        }
    }
}
