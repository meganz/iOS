import Accounts
import MEGAAppPresentation

extension MEGALoginRequestDelegate {
    @objc func handlePostLoginSetup(hasSession: Bool) {
        (UIApplication.shared.delegate as? AppDelegate)?
            .handlePostLoginSetup(isFirstLogin: !hasSession)
    }
    
    @MainActor
    @objc func showLoadingView() {
        if isLoginRegisterAndOnboardingRevampFeatureToggleOn && isNewUserRegistration {
            MEGALinkManager.resetLinkAndURLType()
            guard let window = UIApplication.shared.keyWindow else { return }

            window.rootViewController = AppLoadingViewRouter {
                SubscriptionPurchaseRouter.showSubscriptionPurchaseView(in: window) {
                    fatalError()
                }
            }.build()
        } else {
            PermissionAppLaunchRouter()
                .setRootViewController()
        }
    }

    private var isLoginRegisterAndOnboardingRevampFeatureToggleOn: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp)
    }
}
