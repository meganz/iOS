
import Foundation

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        if UIApplication.mnz_presentingViewController() is AddPhoneNumberViewController || UIApplication.mnz_presentingViewController() is InitialLaunchViewController || UIApplication.mnz_presentingViewController() is LaunchViewController || UIApplication.mnz_presentingViewController() is SMSNavigationViewController ||
            UIApplication.mnz_visibleViewController() is CreateAccountViewController ||
            UIApplication.mnz_visibleViewController() is UpgradeTableViewController ||
            UIApplication.mnz_visibleViewController() is OnboardingViewController ||
            UIApplication.mnz_visibleViewController() is UIAlertController { return }

        if MEGASdkManager.sharedMEGASdk()?.smsAllowedState() != .optInAndUnblock { return }
        
        guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
        
        if let lastDateAddPhoneNumberShowed = UserDefaults.standard.value(forKey: "lastDateAddPhoneNumberShowed") {
            guard let days = Calendar.current.dateComponents([.day], from: lastDateAddPhoneNumberShowed as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }

        UserDefaults.standard.set(Date(), forKey: "lastDateAddPhoneNumberShowed")
        
        let addPhoneNumberController = AddPhoneNumberViewController.mnz_instantiate(withStoryboardName: "SMSVerification")
        addPhoneNumberController.modalPresentationStyle = .fullScreen
        UIApplication.mnz_presentingViewController()?.present(addPhoneNumberController, animated: true, completion: nil)
    }
}
