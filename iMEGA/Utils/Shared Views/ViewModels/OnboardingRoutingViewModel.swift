import Combine
import MEGAAuthentication

@MainActor
/// This view model is used to intercept the routes used in the `OnboardingRoutingViewModel` in the MEGAAuthentication package to trigger the routing in UIKit
final class OnboardingRoutingViewModel {
    let onboardingViewModel: OnboardingViewModel
    private let permissionAppLaunchRouter: any PermissionAppLaunchRouterProtocol
    private var routeToLoadingSubscription: AnyCancellable?
    
    init(
        onboardingViewModel: OnboardingViewModel = MEGAAuthentication.DependencyInjection.onboardingViewModel,
        permissionAppLaunchRouter: some PermissionAppLaunchRouterProtocol
    ) {
        self.onboardingViewModel = onboardingViewModel
        self.permissionAppLaunchRouter = permissionAppLaunchRouter
        setupSubscription()
    }
    
    func presentLoginView(email: String?) {
        let loginViewModel = MEGAAuthentication.DependencyInjection.loginViewModel
        loginViewModel.username = email ?? ""
        
        onboardingViewModel.routeTo(.login(loginViewModel))
    }
    
    private func setupSubscription() {
        routeToLoadingSubscription = onboardingViewModel.$route
            .receive(on: DispatchQueue.main)
            .filter { $0?.isLoggedIn == true }
            .prefix(1)
            .sink { [weak self] _ in
                self?.permissionAppLaunchRouter.setRootViewController()
            }
    }
}
