import MEGAAuthentication
import MEGASwiftUI
import SwiftUI

extension MEGAQuerySignupLinkRequestDelegate {
    @MainActor
    @objc func showLoginFromOnboarding(email: String) {
        guard let rootViewController = UIApplication.mnz_keyWindow()?.rootViewController else {
            return
        }
        
        if rootViewController is OnboardingViewController {
            guard let loginNC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "LoginNavigationControllerID") as? UINavigationController,
                  let loginVC = loginNC.viewControllers.first as? LoginViewController else {return }
            loginVC.emailString = email
            loginVC.modalPresentationStyle = .fullScreen
            
            UIApplication.mnz_presentingViewController().present(loginNC, animated: true)
        } else if let onboardingViewController = rootViewController as? OnboardingUSPViewController {
            onboardingViewController.presentLoginView(email: email)
        } else {
            // Show onboarding since its expected based of previous checks
            (UIApplication.shared.delegate as? AppDelegate)?.showOnboarding(completion: nil)
        }
    }
}
