import MEGAL10n
import SwiftUI

public enum ActiveSubscriptionError: Error {
    case haveCancellablePlan
    case haveNonCancellablePlan
}

public enum UpgradeAccountPlanAlertType {
    case restore(_ status: AlertStatus)
    case purchase(_ status: AlertStatus)
    case activeSubscription(_ errorType: ActiveSubscriptionError, primaryButtonAction: (() -> Void)?)
    
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
        case .activeSubscription:
            return Strings.Localizable.Account.Upgrade.AlreadyHaveASubscription.title
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
        case .activeSubscription(let error, _):
            switch error {
            case .haveCancellablePlan: return Strings.Localizable.Account.Upgrade.AlreadyHaveACancellableSubscription.message
            case .haveNonCancellablePlan: return Strings.Localizable.Account.Upgrade.AlreadyHaveASubscription.message
            }
        }
    }
    
    public var primaryButtonTitle: String {
        if case let .activeSubscription(type, _) = self,
           case .haveCancellablePlan = type {
            return Strings.Localizable.yes
        }

        return Strings.Localizable.ok
    }
    
    public var primaryButtonAction: (() -> Void)? {
        if case let .activeSubscription(type, primaryButtonAction) = self,
           case .haveCancellablePlan = type {
            return primaryButtonAction
        }

        return nil
    }
    
    public var secondaryButtonTitle: String? {
        if case let .activeSubscription(type, _) = self,
           case .haveCancellablePlan = type {
            return Strings.Localizable.no
        }
        
        return nil
    }
}
