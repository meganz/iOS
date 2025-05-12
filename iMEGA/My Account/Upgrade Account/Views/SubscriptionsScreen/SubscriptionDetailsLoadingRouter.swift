import Accounts
import MEGAAppSDKRepo
import MEGADomain

@MainActor
protocol SubscriptionDetailsLoadingRouting {
    func start()
}

struct SubscriptionDetailsLoadingRouter: SubscriptionDetailsLoadingRouting {
    enum SubscriptionPurchaseLoadingError: Error {
        case accountLoadingError
    }

    let window: UIWindow
    let accountUseCase: any AccountUseCaseProtocol
    let onDismiss: (Result<AccountDetailsEntity, SubscriptionPurchaseLoadingError>) -> Void

    func start() {
        window.rootViewController = AppLoadingViewRouter {
            Task {
                do {
                    let viewModel = SubscriptionDetailsLoadingViewModel(accountUseCase: accountUseCase)
                    let accountDetails = try await viewModel.load()
                    onDismiss(.success(accountDetails))
                } catch {
                    onDismiss(.failure(.accountLoadingError))
                }
            }

        }.build()
    }
}
