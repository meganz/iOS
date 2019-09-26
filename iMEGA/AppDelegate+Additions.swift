
import Foundation

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
        
        MEGASdkManager.sharedMEGASdk().getUserData(with: MEGAGenericRequestDelegate() { request, error in
            guard error.type == .apiOk else { return }
            guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
            if UIApplication.mnz_presentingViewController() is AddPhoneNumberViewController { return }
            
            let addPhoneNumberController = AddPhoneNumberViewController.mnz_instantiate(withStoryboardName: "SMSVerification")
            addPhoneNumberController.modalPresentationStyle = .fullScreen
            UIApplication.mnz_presentingViewController()?.present(addPhoneNumberController, animated: true, completion: nil)
        })
    }
}
