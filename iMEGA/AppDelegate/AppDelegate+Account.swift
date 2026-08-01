import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASdk
import QuotaWarnings

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

    /// Called once the main tab bar is the window root, so the dialog has a stable presenter.
    @objc func checkStorageAlmostFullOnAppOpen() {
        showStorageAlmostFullDialogIfNeeded(useCase: .onAppOpen)
    }

    /// Called from `onTransferFinish` for a successful upload.
    @objc func showStorageAlmostFullWarningAfterSuccessfulUpload() {
        showStorageAlmostFullDialogIfNeeded(useCase: .afterSuccessfulUpload)
    }

    private func showStorageAlmostFullDialogIfNeeded(useCase: StorageAlmostFullDialogUseCase) {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .quotaWarningsRevamp) else { return }
        Task { @MainActor in
            do {
                guard try await useCase.shouldShowDialog(),
                      QuotaWarningsRouter().presentStorageDialog(severity: .almostFull) else { return }
                useCase.recordDialogShown()
            } catch {
                MEGALogError("[Storage quota] Could not refresh the storage state: \(error)")
            }
        }
    }
}
