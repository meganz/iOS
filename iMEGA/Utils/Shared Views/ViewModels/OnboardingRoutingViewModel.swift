import Combine
import MEGAAuthentication

@MainActor
/// This view model is used to intercept the routes used in the `OnboardingRoutingViewModel` in the MEGAAuthentication package to trigger the routing in UIKit
final class OnboardingRoutingViewModel {
    let onboardingViewModel: OnboardingViewModel
    typealias LoginSuccess = (_ hasConfirmedAccount: Bool) -> Void
    private let onLoginSuccess: LoginSuccess
    private var routeToLoadingSubscription: AnyCancellable?

    private var hasConfirmedAccount: Bool = false
    private var accountConfirmationTask: Task<Void, Never>?
    private let accountConfirmationUseCase: any AccountConfirmationUseCaseProtocol

    init(
        onboardingViewModel: OnboardingViewModel = MEGAAuthentication.DependencyInjection.onboardingViewModel,
        accountConfirmationUseCase: any AccountConfirmationUseCaseProtocol = MEGAAuthentication.DependencyInjection.accountConfirmationUseCase,
        onLoginSuccess: @escaping LoginSuccess
    ) {
        self.onboardingViewModel = onboardingViewModel
        self.accountConfirmationUseCase = accountConfirmationUseCase
        self.onLoginSuccess = onLoginSuccess
        setupSubscription()
    }

    deinit {
        accountConfirmationTask?.cancel()
    }

    func presentLoginView(email: String?) {
        let loginViewModel = MEGAAuthentication.DependencyInjection.loginViewModel
        loginViewModel.username = email ?? ""
        
        onboardingViewModel.routeTo(.login(loginViewModel))
    }
    
    func presentSignUpView(email: String? = nil) {
        let createAccountViewModel = MEGAAuthentication.DependencyInjection.createAccountViewModel
        createAccountViewModel.email = email ?? ""
        
        onboardingViewModel.routeTo(.signUp(createAccountViewModel))
    }

    private func setupSubscription() {
        setupAccountConfirmationSubscription()
        setupLoggedInSubscription()
    }

    private func setupLoggedInSubscription() {
        routeToLoadingSubscription = onboardingViewModel.$route
            .receive(on: DispatchQueue.main)
            .filter { $0?.isLoggedIn == true }
            .prefix(1)
            .sink { [weak self] _ in
                guard let self else { return }
                onLoginSuccess(hasConfirmedAccount)
            }
    }

    private func setupAccountConfirmationSubscription() {
        self.accountConfirmationTask = Task { [accountConfirmationUseCase, weak self] in
            await accountConfirmationUseCase.waitForAccountConfirmationEvent()
            self?.hasConfirmedAccount = true
        }
    }
}
