import Combine
import MEGAAccountManagement
import MEGAAuthentication
import SwiftUI

@MainActor
final class LaunchViewModel: ObservableObject {
    enum Route {
        case onboarding(OnboardingViewModel)
        case home(HomeViewModel)
    }

    @Published var route: Route?

    private var cancellables: Set<AnyCancellable> = []

    init(route: Route? = nil) {
        self.route = route
    }

    func onAppear() {
        presentOnboarding()
    }

    func didLogout() {
        presentOnboarding()
    }

    private func presentOnboarding() {
        let viewModel = MEGAAuthentication.DependencyInjection.onboardingViewModel
        viewModel.$route.sink { [weak self] route in
            switch route {
            case .loggedIn: self?.presentHome()
            default: break
            }
        }.store(in: &cancellables)
        route = .onboarding(viewModel)
    }

    private func presentHome() {
        route = .home(.liveValue)
    }
}
