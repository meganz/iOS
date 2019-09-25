
import Foundation

extension MEGASdk {
    @objc var hasVerifiedPhoneNumber: Bool {
        let isPhoneNumberEmpty = MEGASdkManager.sharedMEGASdk()?.smsVerifiedPhoneNumber()?.isEmpty ?? true
        return !isPhoneNumberEmpty
    }
    
    @objc func handleAccountBlockedEvent(_ event: MEGAEvent) {
        guard let suspensionType = AccountSuspensionType(rawValue: event.number) else { return }
        let state = smsAllowedState()
        if suspensionType == .smsVerification && state != .notAllowed {
            if UIApplication.mnz_presentingViewController() is SMSNavigationViewController {
                return
            }
            
            UIApplication.mnz_presentingViewController()?.present(SMSNavigationViewController(rootViewController: SMSVerificationViewController.instantiate(with: .UnblockAccount)), animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: AMLocalizedString("error"), message: AMLocalizedString("accountBlocked", "Error message when trying to login and the account is blocked"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: AMLocalizedString("ok"), style: .cancel, handler: { _ in
                self.logout()
            }))
            UIApplication.mnz_presentingViewController()?.present(alert, animated: true, completion: nil)
        }
    }
}
