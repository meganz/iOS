
import Foundation

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        if UIApplication.mnz_presentingViewController() is AddPhoneNumberViewController || UIApplication.mnz_presentingViewController() is InitialLaunchViewController || UIApplication.mnz_presentingViewController() is LaunchViewController || UIApplication.mnz_presentingViewController() is SMSNavigationViewController { return }

        if MEGASdkManager.sharedMEGASdk()?.smsAllowedState() != .optInAndUnblock { return }
        
        guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
        
        let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier)
        if let lastDateAddPhoneNumberShowed = sharedUserDefaults?.value(forKey: "lastDateAddPhoneNumberShowed") {
            guard let days = Calendar.current.dateComponents([.day], from: lastDateAddPhoneNumberShowed as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }

        sharedUserDefaults?.set(Date(), forKey: "lastDateAddPhoneNumberShowed")
        
        let addPhoneNumberController = AddPhoneNumberViewController.mnz_instantiate(withStoryboardName: "SMSVerification")
        addPhoneNumberController.modalPresentationStyle = .fullScreen
        UIApplication.mnz_presentingViewController()?.present(addPhoneNumberController, animated: true, completion: nil)
    }
}
