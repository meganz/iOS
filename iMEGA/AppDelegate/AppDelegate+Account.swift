
extension AppDelegate {
    @objc func expiredAccountTitle() -> String {
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
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
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
            return ""
        }
        switch accountDetails.type {
        case .proFlexi:
            return Strings.Localizable.Account.Expired.ProFlexi.message
        default:
            if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
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
        guard FeatureFlagProvider().isFeatureFlagEnabled(for: .mandatoryFingerprintVerification) else { return }
        CustomModalAlertRouter(.upgradeSecurity, presenter: UIApplication.mnz_presentingViewController()).start()
    }
}
