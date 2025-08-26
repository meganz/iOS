import MEGAAppSDKRepo
import MEGADomain

@MainActor
protocol UpgradeSubscriptionRouting {
    func showUpgradeAccount()
}

final class UpgradeSubscriptionRouter: UpgradeSubscriptionRouting {
    private weak var presenter: UIViewController?
    private let onDismiss: (() -> Void)?
    private let isFromAds: Bool
    
    init(
        presenter: UIViewController?,
        isFromAds: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.presenter = presenter
        self.isFromAds = isFromAds
        self.onDismiss = onDismiss
    }
    
    func showUpgradeAccount() {
        let accountUseCase = AccountUseCase(
            repository: AccountRepository.newRepo)
        guard let currentAccountDetails = accountUseCase.currentAccountDetails else {
            MEGALogError("[\(type(of: self))]: Could not retrieve current account details")
            return
        }
        SubscriptionPurchaseRouter(
            presenter: presenter,
            currentAccountDetails: currentAccountDetails,
            viewType: .upgrade,
            accountUseCase: accountUseCase,
            isFromAds: isFromAds,
            onDismiss: onDismiss)
        .start()
    }
}
