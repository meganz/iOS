import Accounts
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

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
            let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
            let coordinator = SubscriptionPurchaseViewCoordinator(window: window, accountUseCase: accountUseCase) {
                // Note: The fetching/loading of nodes was already done by SubscriptionPurchaseViewCoordinator
                // Therefore the PermissionAppLaunchRouter doesn't need to show loading screen again.
                PermissionAppLaunchRouter().setRootViewController(shouldShowLoadingScreen: false)
            }
            coordinator.start()
        } else {
            PermissionAppLaunchRouter().setRootViewController(shouldShowLoadingScreen: true)
        }
    }

    private var isLoginRegisterAndOnboardingRevampFeatureToggleOn: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp)
    }
}
