import Accounts
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

protocol ProfileViewRouting: Routing {
    func showCancelAccountPlan(
        currentSubscription: AccountSubscriptionEntity,
        currentPlan: PlanEntity,
        freeAccountStorageLimit: Int,
        assets: CancelAccountPlanAssets
    )
    func showCancellationSteps()
    func showRecoveryKey()
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
            achievementUseCase: AchievementUseCase(repo: AchievementRepository.newRepo),
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
        currentSubscription: AccountSubscriptionEntity,
        currentPlan: PlanEntity,
        freeAccountStorageLimit: Int,
        assets: CancelAccountPlanAssets
    ) {
        guard let nav = navigationController else { return }
        
        CancelAccountPlanRouter(
            currentSubscription: currentSubscription,
            freeAccountStorageLimit: freeAccountStorageLimit,
            accountUseCase: accountUseCase,
            currentPlan: currentPlan,
            assets: assets,
            navigationController: nav,
            onSuccess: { expirationDate, storageLimit in
                CustomModalAlertRouter(
                    .cancelSubscription,
                    presenter: UIApplication.mnz_presentingViewController(),
                    expirationDate: expirationDate,
                    storageLimit: storageLimit
                ).start()
            },
            onFailure: { actionCallback in
                CustomModalAlertRouter(
                    .cancelSubscriptionError,
                    presenter: UIApplication.mnz_presentingViewController(),
                    actionHandler: {
                        ReportIssueViewRouter(
                            presenter: UIApplication.mnz_visibleViewController(),
                            onViewDismissed: {
                                actionCallback()
                            }
                        ).start()
                    }
                ).start()
            },
            featureFlagProvider: DIContainer.featureFlagProvider,
            logger: { MEGALogError($0) }
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
    
    func showRecoveryKey() {
        RecoveryKeyViewRouter(navigationController: navigationController).start()
    }
}
