import MEGAAppPresentation
import MEGAAuthentication
import MEGASwiftUI
import SwiftUI

extension MEGAQuerySignupLinkRequestDelegate {
    @MainActor
    @objc func showLoginFromOnboarding(email: String) {
        guard let rootViewController = UIApplication.mnz_keyWindow()?.rootViewController else {
            return
        }
        
        if let onboardingViewController = rootViewController as? OnboardingUSPViewController {
            onboardingViewController.presentLoginView(email: email)
        } else {
            // Show onboarding since its expected based of previous checks
            (UIApplication.shared.delegate as? AppDelegate)?.showOnboarding(completion: nil)
        }
    }
    
    @MainActor
    @objc func showRegistrationFromOnboarding() {
        guard let rootViewController = UIApplication.mnz_keyWindow()?.rootViewController else {
            return
        }
        if let onboardingViewController = rootViewController as? OnboardingUSPViewController {
            onboardingViewController.presentSignUpView(
                email: MEGALinkManager.emailOfNewSignUpLink)
        }
        
        MEGALinkManager.emailOfNewSignUpLink = nil
    }
}
