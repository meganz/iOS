
import Foundation

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
        
        MEGASdkManager.sharedMEGASdk().getUserData(with: MEGAGenericRequestDelegate(completion: { (request, error) in
            guard error.type == .apiOk else { return }
            guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
            
            UIApplication.mnz_presentingViewController()?.present(AddPhoneNumberViewController.mnz_instantiate(withStoryboardName: "SMSVerification"), animated: true, completion: nil)
        }))
    }
}
