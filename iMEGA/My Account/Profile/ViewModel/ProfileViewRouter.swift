import Accounts
import MEGADomain
import MEGAPresentation

protocol ProfileViewRouting: Routing {
    func showCancelSubscriptionFlow(accountDetails: AccountDetailsEntity, assets: CurrentPlanDetailAssets)
}

final class ProfileViewRouter: ProfileViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let accountUseCase: any AccountUseCaseProtocol
    
    init(
        navigationController: UINavigationController?,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.accountUseCase = accountUseCase
    }
    
    func build() -> UIViewController {
        let viewModel = ProfileViewModel(
            accountUseCase: accountUseCase,
            router: self
        )
        
        let viewController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(identifier: "ProfileViewControllerID", creator: { coder in
            ProfileViewController(coder: coder, viewModel: viewModel)
        })
        
        baseViewController = viewController
        
        return viewController
    }
    
    func start() {
        guard let navigationController else {
            assertionFailure("Must pass UINavigationController in ProfileViewRouter")
            MEGALogDebug("[Profile] No UINavigationController passed on ProfileViewRouter")
            return
        }

        navigationController.pushViewController(build(), animated: true)
    }
    
    func showCancelSubscriptionFlow(
        accountDetails: AccountDetailsEntity,
        assets: CurrentPlanDetailAssets
    ) {
        guard let presenter = baseViewController else { return }
        
        CurrentPlanDetailRouter(
            accountDetails: accountDetails,
            assets: assets,
            presenter: presenter
        ).start()
    }
}
