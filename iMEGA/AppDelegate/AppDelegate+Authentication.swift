import Accounts
import MEGAAppPresentation
import MEGAAuthentication
import MEGAPermissions
import MEGASwiftUI
import SwiftUI

extension AppDelegate {
    @objc func injectAuthenticationDependencies() {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp) else { return }
        
        MEGAAuthentication.DependencyInjection.sharedSdk = .shared
        MEGAAuthentication.DependencyInjection.keychainServiceName = "MEGA"
        MEGAAuthentication.DependencyInjection.keychainAccount = "sessionV3"
        MEGAAuthentication.DependencyInjection.updateDuplicateSessionForLogin = true
    }
    
    @objc func makeOnboardingViewController() -> UIViewController {
        if  DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp) {
            makeNewOnboardingViewController()
        } else {
            OnboardingViewController.instantiateOnboarding(with: .default)
        }
    }
    
    private func makeNewOnboardingViewController() -> UIViewController {
        let viewModel = MEGAAuthentication.DependencyInjection.onboardingViewModel
        routeToLoadingSubscription = viewModel.$route
            .sink { [weak self] in
                guard $0?.isLoggedIn == true else { return }
                self?.routeToLoadingSubscription = nil
                
                Task { @MainActor in
                    let permissionHandler = DevicePermissionsHandler.makeHandler()
                    let shouldSetupPermissions = await permissionHandler.shouldSetupPermissions()
                    self?.showLoadingView(permissionsPending: shouldSetupPermissions)
                }
                
            }
        
        let view = OnboardingView(
            viewModel: viewModel,
            onboardingCarouselContent: []) {
                LoadingSpinner()
            }
        return  UIHostingController(rootView: view)
    }
    
    @MainActor
    @objc func showLoadingView(permissionsPending: Bool) {
        var viewController: UIViewController?
        if permissionsPending {
            viewController = AppLoadingViewRouter {
                guard let launchViewController = UIStoryboard(
                    name: "Launch",
                    bundle: nil
                ).instantiateViewController(
                    withIdentifier: "InitialLaunchViewControllerID"
                ) as? InitialLaunchViewController else {
                    return
                }
                launchViewController.delegate = UIApplication.shared.delegate as? any LaunchViewControllerDelegate
                guard let window = UIApplication.shared.keyWindow else {
                    return
                }
                launchViewController.showViews = true
                window.rootViewController = launchViewController
            }.build()
        } else {
            viewController = AppLoadingViewRouter {
                guard let launchViewController = UIStoryboard(
                    name: "Launch",
                    bundle: nil
                ).instantiateViewController(
                    withIdentifier: "LaunchViewControllerID"
                ) as? LaunchViewController else {
                    return
                }
                launchViewController.delegate = UIApplication.shared.delegate as? any LaunchViewControllerDelegate
                launchViewController.delegate.setupFinished()
                launchViewController.delegate.readyToShowRecommendations()
            }
            .build()
        }
        
        guard let window = UIApplication.shared.keyWindow else { return }
        window.rootViewController = viewController
    }
}
