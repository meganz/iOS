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
                fatalError()
            }
            coordinator.start()
        } else {
            PermissionAppLaunchRouter().setRootViewController()
        }
    }

    private var isLoginRegisterAndOnboardingRevampFeatureToggleOn: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp)
    }
}
