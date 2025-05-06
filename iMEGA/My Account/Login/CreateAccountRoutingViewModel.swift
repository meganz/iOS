import Combine
import MEGAAuthentication

@MainActor
/// This view model is used to intercept the routes used in the `CreateAccountViewModel` in the MEGAAuthentication package to trigger the routing in UIKit via router
final class CreateAccountRoutingViewModel {
    let createAccountViewModel: CreateAccountViewModel
    private let router: any LoginRouterProtocol
    private var routeToSubscription: AnyCancellable?
    
    init(
        createAccountViewModel: CreateAccountViewModel = MEGAAuthentication.DependencyInjection.createAccountViewModel,
        router: some LoginRouterProtocol
    ) {
        self.createAccountViewModel = createAccountViewModel
        self.router = router
        setupSubscription()
    }
    
    deinit {
        routeToSubscription?.cancel()
    }
    
    private func setupSubscription() {
        routeToSubscription = createAccountViewModel.$route
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] in
                guard let self else { return }
                switch $0 {
                case .login:
                    router.dismiss {
                        self.router.showLogin()
                    }
                case .loggedIn:
                    router.showPermissionLoading()
                case .dismissed:
                    router.dismiss(completion: nil)
                default: break
                }
            }
    }
}
