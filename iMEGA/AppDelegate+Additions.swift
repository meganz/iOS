
import Foundation

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        if MEGASdkManager.sharedMEGASdk()?.smsVerifiedPhoneNumber()?.isEmpty ?? true {   
            UIApplication.mnz_presentingViewController()?.present(AddPhoneNumberViewController.instantiate(withStoryboardName: "SMSVerification"), animated: true, completion: nil)
        }
    }
}
