
enum UpgradeAccountPlanAlertType {
    case restore(_ status: AlertStatus)
    case purchase(_ status: AlertStatus)
    
    enum AlertStatus {
        case success, incomplete, failed
    }
    
    var title: String {
        switch self {
        case .restore(let status):
            switch status {
            case .success: return Strings.Localizable.thankYouTitle
            case .incomplete: return Strings.Localizable.incompleteRestoreTitle
            case .failed: return Strings.Localizable.failedRestoreTitle
            }
        default: return ""
        }
    }
    
    var message: String {
        switch self {
        case .restore(let status):
            switch status {
            case .success: return Strings.Localizable.purchaseRestoreMessage
            case .incomplete: return Strings.Localizable.incompleteRestoreMessage
            case .failed: return Strings.Localizable.failedRestoreMessage
            }
        default: return ""
        }
    }
}
