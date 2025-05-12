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
    
    @MainActor
    @objc func showRegistrationFromOnboarding() {
        guard let rootViewController = UIApplication.mnz_keyWindow()?.rootViewController else {
            return
        }
        if rootViewController is OnboardingViewController {
            guard let createNC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "CreateAccountNavigationControllerID") as? UINavigationController,
                  let createVC = createNC.viewControllers.first as? CreateAccountViewController else { return }
            createVC.emailString = MEGALinkManager.emailOfNewSignUpLink
            createVC.modalPresentationStyle = .fullScreen
            
            UIApplication.mnz_presentingViewController().present(createNC, animated: true)
        } else if let onboardingViewController = rootViewController as? OnboardingUSPViewController {
            onboardingViewController.presentSignUpView(
                email: MEGALinkManager.emailOfNewSignUpLink)
        }
        
        MEGALinkManager.emailOfNewSignUpLink = nil
    }
}
