import MEGADomain
import MEGAPresentation
import MEGASDKRepo

protocol OverDiskQuotaViewRouting: Routing {
    func dismiss()
    func showUpgradePlanPage()
    func navigateToCloudDriveTab()
}

final class OverDiskQuotaViewRouter: OverDiskQuotaViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private weak var mainTabBar: MainTabBarController?
    private let overDiskQuotaInfomation: any OverDiskQuotaInfomationProtocol
    private let dismissCompletionAction: (() -> Void)?
    private let presentCompletionAction: (() -> Void)?
    
    init(
        presenter: UIViewController?,
        mainTabBar: MainTabBarController?,
        overDiskQuotaInfomation: some OverDiskQuotaInfomationProtocol,
        dismissCompletionAction: (() -> Void)?,
        presentCompletionAction: (() -> Void)?
    ) {
        self.presenter = presenter
        self.mainTabBar = mainTabBar
        self.overDiskQuotaInfomation = overDiskQuotaInfomation
        self.dismissCompletionAction = dismissCompletionAction
        self.presentCompletionAction = presentCompletionAction
    }
    
    func dismiss() {
        baseViewController?.dismiss(animated: true, completion: dismissCompletionAction)
    }
    
    func showUpgradePlanPage() {
        guard let currentAccountDetails = AccountUseCase(repository: AccountRepository.newRepo).currentAccountDetails else {
            return
        }
        
        UpgradeAccountPlanRouter(
            presenter: baseViewController,
            accountDetails: currentAccountDetails
        ).start()
    }
    
    func navigateToCloudDriveTab() {
        mainTabBar?.selectedIndex = TabType.cloudDrive.rawValue
        
        guard let navigationController = mainTabBar?.children.first as? UINavigationController else {
            dismiss()
            return
        }
        
        if let cdViewController = navigationController.viewControllers.last as? NewCloudDriveViewController {
            if cdViewController.displayModeProvider.displayMode() != .cloudDrive {
                navigationController.popToRootViewController(animated: true)
            }
        } else {
            navigationController.popToRootViewController(animated: true)
        }

        dismiss()
    }
    
    func build() -> UIViewController {
        let odqViewController = OverDiskQuotaViewController(
            viewModel: OverDiskQuotaViewModel(router: self),
            overDiskQuotaData: overDiskQuotaInfomation
        )
        
        let navigationController = UINavigationController(rootViewController: odqViewController)
        navigationController.modalPresentationStyle = .fullScreen
        baseViewController = navigationController
        return navigationController
    }
    
    func start() {
        presenter?.present(build(), animated: true, completion: presentCompletionAction)
    }
}
