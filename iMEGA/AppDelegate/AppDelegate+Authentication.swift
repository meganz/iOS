import Accounts
import MEGAAnalytics
import MEGAAppPresentation
import MEGAAuthentication
import MEGAAuthenticationOrchestration
import MEGAPermissions
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

extension AppDelegate {
    @objc func injectAuthenticationDependencies() {
        guard isLoginRegisterAndOnboardingRevampFeatureEnabled else { return }

        MEGAAuthentication.DependencyInjection.sharedSdk = .shared
        MEGAAuthentication.DependencyInjection.keychainServiceName = "MEGA"
        MEGAAuthentication.DependencyInjection.keychainAccount = "sessionV3"
        MEGAAuthentication.DependencyInjection.snackbarDisplayer = VisibleViewControllerSnackBarDisplayer()
        
        MEGAAuthentication.DependencyInjection.loginUseCase = LoginWithPostActionsUseCase(
            loginUseCase: LoginUseCase(
                fetchNodesEnabled: false,
                shouldIncludeFastLoginTimeout: false,
                updateDuplicateSession: true,
                loginAPIRepository: MEGAAuthentication.DependencyInjection.loginAPIRepository,
                loginStoreRepository: MEGAAuthentication.DependencyInjection.loginStoreRepository),
            postLoginActions: [AppDelegatePostLoginAction(appDelegate: self)])
        
        MEGAAuthentication.DependencyInjection.createAccountUseCase = KeychainStoringCreateAccountUseCase(
            createAccountUseCase: CreateAccountUseCase(
                repository: CreateAccountRepository(
                    sdk: MEGAAuthentication.DependencyInjection.sharedSdk)),
            keychainRepository: MEGAAuthentication.DependencyInjection.keychainRepository)
        
        MEGAAuthentication.DependencyInjection.analyticsTracker = AnalyticsTrackerAdapter()
    }
    
    @objc func makeOnboardingViewController() -> UIViewController {
        if isLoginRegisterAndOnboardingRevampFeatureEnabled {
            OnboardingUSPViewController()
        } else {
            OnboardingViewController.instantiateOnboarding(with: .default)
        }
    }
    
    @objc func isRootViewNewOnboarding() -> Bool {
        window.rootViewController is UIHostingController<OnboardingView<LoadingSpinner>>
    }
    
    @objc func handlePostLoginSetup(isFirstLogin: Bool) {
        setAccountFirstLogin(isFirstLogin)
        postLoginNotification()
        initProviderDelegate()
        registerForNotifications()
        
        MEGASdk.shared.fetchNodes()
        
        QuickAccessWidgetManager.reloadAllWidgetsContent()
        
        MEGAPurchase.sharedInstance().requestPricing()
    }
    
    @objc func isOnboardingViewControllerAlreadyShown() -> Bool {
        if  isLoginRegisterAndOnboardingRevampFeatureEnabled {
            isRootViewNewOnboarding()
        } else {
            window.rootViewController is OnboardingViewController
        }
    }

    @objc var isLoginRegisterAndOnboardingRevampFeatureEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp)
    }
}

private struct AppDelegatePostLoginAction: PostLoginAction {
    let appDelegate: AppDelegate
    
    @MainActor
    func handlePostLogin() async throws {
        appDelegate.handlePostLoginSetup(isFirstLogin: true)
    }
}

private struct AnalyticsTrackerAdapter: MEGAAnalyticsTrackerProtocol {
    private let tracker: any MEGAAppPresentation.AnalyticsTracking

    init(tracker: some MEGAAppPresentation.AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }

    func trackAnalyticsEvent(with event: some MEGAAnalytics.AnalyticsEventEntityProtocol) {
        guard let identifer = event.identifier else { return }
        tracker.trackAnalyticsEvent(with: identifer)
    }
}

private struct VisibleViewControllerSnackBarDisplayer: SnackbarDisplaying {
    func display(_ snackbar: SnackbarEntity) {
        Task { @MainActor in
            UIApplication.mnz_visibleViewController()
                .showSnackBar(snackBar: snackbar.toSnackbar())
        }
    }
}

private extension SnackbarEntity {
    func toSnackbar() -> SnackBar {
        let action: SnackBar.Action? = if let actionLabel,
                                          let action {
            .init(title: actionLabel, handler: action)
        } else {
            nil
        }
        return .init(
            message: text,
            action: action)
    }
}
