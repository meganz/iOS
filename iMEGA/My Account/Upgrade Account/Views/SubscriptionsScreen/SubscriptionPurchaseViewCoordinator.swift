import Accounts
import MEGAAppSDKRepo
import MEGADomain

struct SubscriptionPurchaseViewCoordinator {
    private let window: UIWindow
    private let isNewUserRegistration: Bool
    private let accountUseCase: any AccountUseCaseProtocol
    private let onDismiss: () -> Void

    init(
        window: UIWindow,
        isNewUserRegistration: Bool,
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        onDismiss: @escaping () -> Void
    ) {
        self.window = window
        self.isNewUserRegistration = isNewUserRegistration
        self.accountUseCase = accountUseCase
        self.onDismiss = onDismiss
    }

    @MainActor
    func start() {
        let loadingRouter = SubscriptionDetailsLoadingRouter(
            window: window,
            accountUseCase: accountUseCase,
        ) { route in
            switch route {
            case .goPro(let accountDetails):
                let router = SubscriptionPurchaseRouter(
                    presenter: nil,
                    currentAccountDetails: accountDetails,
                    viewType: .onboarding(isFreeAccountFirstLogin: !isNewUserRegistration),
                    accountUseCase: accountUseCase,
                    onDismiss: onDismiss
                )
                window.rootViewController = router.build()
            case .dismiss:
                onDismiss()
            }
        }

        loadingRouter.start()
    }
}
