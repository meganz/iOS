
import Foundation

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if  visibleViewController is AddPhoneNumberViewController ||
            visibleViewController is InitialLaunchViewController ||
            visibleViewController is LaunchViewController ||
            visibleViewController is SMSVerificationViewController ||
            visibleViewController is VerificationCodeViewController ||
            visibleViewController is CreateAccountViewController ||
            visibleViewController is UpgradeTableViewController ||
            visibleViewController is OnboardingViewController ||
            visibleViewController is UIAlertController { return }

        if MEGASdkManager.sharedMEGASdk()?.smsAllowedState() != .optInAndUnblock { return }
        
        guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
        
        if let lastDateAddPhoneNumberShowed = UserDefaults.standard.value(forKey: "lastDateAddPhoneNumberShowed") {
            guard let days = Calendar.current.dateComponents([.day], from: lastDateAddPhoneNumberShowed as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }

        UserDefaults.standard.set(Date(), forKey: "lastDateAddPhoneNumberShowed")
        
        let addPhoneNumberController = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "AddPhoneNumberViewControllerID")
        addPhoneNumberController.modalPresentationStyle = .fullScreen
        UIApplication.mnz_presentingViewController()?.present(addPhoneNumberController, animated: true, completion: nil)
    }
}
