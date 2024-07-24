import Accounts
import MEGADomain
import MEGAPresentation

protocol ProfileViewRouting: Routing {
    func showCancelAccountPlan(currentPlan: PlanEntity, accountDetails: AccountDetailsEntity, assets: CancelAccountPlanAssets)
    func showCancellationSteps()
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
            tracker: DIContainer.tracker,
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
    
    func showCancelAccountPlan(
        currentPlan: PlanEntity,
        accountDetails: AccountDetailsEntity,
        assets: CancelAccountPlanAssets
    ) {
        guard let presenter = baseViewController else { return }
        
        CancelAccountPlanRouter(
            accountDetails: accountDetails,
            currentPlan: currentPlan,
            assets: assets,
            presenter: presenter
        ).start()
    }
    
    func showCancellationSteps() {
        guard let presenter = baseViewController else { return }
        // Assuming that we are only going to show the cancellation steps for accounts with Pro Flexi subscriptions and that these subscriptions can only be purchased from the web client.
        CancelSubscriptionStepsRouter(
            type: .webClient,
            presenter: presenter
        ).start()
    }
}
