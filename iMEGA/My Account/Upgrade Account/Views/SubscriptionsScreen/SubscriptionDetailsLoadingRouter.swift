import Accounts
import MEGAAppSDKRepo
import MEGADomain

@MainActor
protocol SubscriptionDetailsLoadingRouting {
    func start()
}

struct SubscriptionDetailsLoadingRouter: SubscriptionDetailsLoadingRouting {
    let window: UIWindow
    let accountUseCase: any AccountUseCaseProtocol
    let onDismiss: (SubscriptionDetailsLoadingViewModel.Route) -> Void

    func start() {
        window.rootViewController = AppLoadingViewRouter {
            Task {
                let viewModel = SubscriptionDetailsLoadingViewModel(
                    accountUseCase: accountUseCase)
                let route = await viewModel.determineRoute()
                onDismiss(route)
            }

        }.build()
    }
}
