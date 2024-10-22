import MEGADomain
import MEGAL10n
import MEGASdk

extension AppDelegate {
    @objc func expiredAccountTitle() -> String {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else {
            return ""
        }
        switch accountDetails.type {
        case .proFlexi:
            return Strings.Localizable.Account.Expired.ProFlexi.title
        default:
            return Strings.Localizable.yourBusinessAccountIsExpired
        }
    }
    
    @objc func expiredAccountMessage() -> String {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else {
            return ""
        }
        switch accountDetails.type {
        case .proFlexi:
            return Strings.Localizable.Account.Expired.ProFlexi.message
        default:
            if MEGASdk.shared.isMasterBusinessAccount {
                return Strings.Localizable.ThereHasBeenAProblemProcessingYourPayment.megaIsLimitedToViewOnlyUntilThisIssueHasBeenFixedInADesktopWebBrowser
            } else {
                let message = Strings.Localizable.YourAccountIsCurrentlyBSuspendedB.youCanOnlyBrowseYourData
                    .replacingOccurrences(of: "[B]", with: "")
                    .replacingOccurrences(of: "[/B]", with: "")
                    .appending("\n\n")
                    .appending(Strings.Localizable.contactYourBusinessAccountAdministratorToResolveTheIssueAndActivateYourAccount)
                return message
            }
        }
    }
    
    @objc func showUpgradeSecurityAlert() {
        CustomModalAlertRouter(.upgradeSecurity, presenter: UIApplication.mnz_presentingViewController()).start()
    }
    
    @objc func postLoginNotification() {
        NotificationCenter.default.post(name: .accountDidLogin, object: nil)
    }
    
    @objc func postDidFinishFetchNodesNotification() {
        NotificationCenter.default.post(name: .accountDidFinishFetchNodes, object: nil)
    }
    
    @objc func postSetShouldRequestAccountDetailsNotification(_ shouldRequest: Bool) {
        NotificationCenter.default.post(name: .setShouldRefreshAccountDetails, object: shouldRequest)
    }
    
    @objc func postDidFinishFetchAccountDetailsNotification(accountDetails: MEGAAccountDetails?) {
        NotificationCenter.default.post(name: .accountDidFinishFetchAccountDetails, object: accountDetails?.toAccountDetailsEntity())
    }
}
