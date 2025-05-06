import Combine
import MEGAAuthentication

@MainActor
/// This view model is used to intercept the routes used in the `LoginViewModel` in the MEGAAuthentication package to trigger the routing in UIKit via router
final class LoginRoutingViewModel {
    let loginViewModel: LoginViewModel
    private let router: any LoginRouterProtocol
    private var routeToSubscription: AnyCancellable?
    
    init(
        loginViewModel: LoginViewModel = MEGAAuthentication.DependencyInjection.loginViewModel,
        router: some LoginRouterProtocol
    ) {
        self.loginViewModel = loginViewModel
        self.router = router
        setupSubscription()
    }
    
    deinit {
        routeToSubscription?.cancel()
    }
    
    private func setupSubscription() {
        routeToSubscription = loginViewModel.$route
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] in
                guard let self else { return }
                switch $0 {
                case .loggedIn:
                    router.showPermissionLoading()
                case .signUp:
                    router.dismiss {
                        self.router.showSignUp()
                    }
                case .dismissed:
                    router.dismiss(completion: nil)
                default: break
                }
            }
    }
}
