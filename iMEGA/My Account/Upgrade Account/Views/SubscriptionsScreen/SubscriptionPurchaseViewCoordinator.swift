import Accounts
import MEGAAppSDKRepo
import MEGADomain

struct SubscriptionPurchaseViewCoordinator {
    private let window: UIWindow
    private let accountUseCase: any AccountUseCaseProtocol
    private let onDismiss: () -> Void

    init(
        window: UIWindow,
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        onDismiss: @escaping () -> Void
    ) {
        self.window = window
        self.accountUseCase = accountUseCase
        self.onDismiss = onDismiss
    }

    @MainActor
    func start() {
        let loadingRouter = SubscriptionDetailsLoadingRouter(
            window: window,
            accountUseCase: accountUseCase,
        ) { result in
            switch result {
            case .success(let accountDetails):
                let router = SubscriptionPurchaseRouter(
                    window: window,
                    currentAccountDetails: accountDetails,
                    accountUseCase: accountUseCase,
                    onDismiss: onDismiss
                )
                router.start()
            case .failure:
                onDismiss()
            }
        }

        loadingRouter.start()
    }
}
