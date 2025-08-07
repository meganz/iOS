import MEGAAppPresentation
import MEGADomain
import MEGASwiftUI
import Notifications

protocol NotificationsViewRouting: Routing {
    func navigateThroughNodeHierarchy(_ nodeHierarchy: [NodeEntity], isOwnNode: Bool, isInRubbishBin: Bool)
    func navigateThroughNodeHierarchyAndPresent(_ node: NodeEntity)
}

struct NotificationsViewRouter: NotificationsViewRouting {
    private weak var navigationController: UINavigationController?
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let imageLoader: any ImageLoadingProtocol
    private let hidesBottomBarWhenPushed: Bool

    private var isNavigationRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)
    }

    init(
        navigationController: UINavigationController?,
        notificationsUseCase: some NotificationsUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        imageLoader: some ImageLoadingProtocol,
        hidesBottomBarWhenPushed: Bool = false
    ) {
        self.navigationController = navigationController
        self.notificationsUseCase = notificationsUseCase
        self.nodeUseCase = nodeUseCase
        self.imageLoader = imageLoader
        self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
    }
    
    func build() -> UIViewController {
        guard let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewController(withIdentifier: "NotificationsTableViewControllerID") as? NotificationsTableViewController else {
            fatalError("Failed to load NotificationsTableViewController")
        }
        
        let viewModel = NotificationsViewModel(
            router: self,
            notificationsUseCase: notificationsUseCase,
            nodeUseCase: nodeUseCase,
            imageLoader: imageLoader,
            tracker: DIContainer.tracker
        )
        notificationsVC.viewModel = viewModel
        notificationsVC.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
        return notificationsVC
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func navigateThroughNodeHierarchy(
        _ nodeHierarchy: [NodeEntity],
        isOwnNode: Bool,
        isInRubbishBin: Bool
    ) {
        guard let mainTBC = UIApplication.mainTabBarRootViewController() as? MainTabBarController else {
            return
        }

        resetCurrentNavigationController()
        
        selectTabController(in: mainTBC, isOwnNode: isOwnNode)
        
        guard let navigationController = mainTBC.selectedViewController as? UINavigationController else {
            return assertionFailure("Opening a node from notification but couldn't find the target navigation controller in the tab bar.")
        }

        navigationController.popToRootViewController(animated: false)
        
        pushNodeHierarchy(
            in: navigationController,
            nodeHierarchy: nodeHierarchy,
            isInRubbishBin: isInRubbishBin
        )
    }
    
    private func selectTabController(in mainTBC: MainTabBarController, isOwnNode: Bool) {
        if isOwnNode {
            mainTBC.selectedIndex = TabManager.driveTabIndex()
        } else {
            if isNavigationRevampEnabled {
                mainTBC.selectedIndex = TabManager.menuTabIndex()
                openSharedItemsFromMenu(in: mainTBC)
            } else {
                mainTBC.selectedIndex = TabManager.sharedItemsTabIndex()
                selectSharedSegmentIfNeeded(in: mainTBC)
            }
        }
    }

    private func openSharedItemsFromMenu(in mainTBC: MainTabBarController) {
        guard let presenter = mainTBC.selectedViewController as? (any AccountMenuItemsNavigating) else {
            return assertionFailure("Trying to navigate to SharedItems screen but selected view controller is not of type AccountMenuItemsNavigating")
        }
        presenter.showSharedItems()
    }

    private func selectSharedSegmentIfNeeded(in mainTBC: MainTabBarController) {
        if let sharedNav = mainTBC.selectedViewController as? UINavigationController,
           let sharedItemsVC = sharedNav.children.first as? SharedItemsViewController {
            sharedItemsVC.selectSegment(0)
        }
    }
    
    private func pushNodeHierarchy(
        in navigationController: UINavigationController,
        nodeHierarchy: [NodeEntity],
        isInRubbishBin: Bool
    ) {
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        
        pushIntermediateNodes(
            in: navigationController,
            using: factory,
            nodeHierarchy: nodeHierarchy.dropLast()
        )
        
        pushCloudDriveViewController(
            nodeHierarchy.last,
            in: navigationController,
            using: factory,
            isInRubbishBin: isInRubbishBin
        )
        
        cancelRootSearchIfNeeded(in: navigationController)
    }

    private func pushIntermediateNodes(
        in navigationController: UINavigationController,
        using factory: CloudDriveViewControllerFactory,
        nodeHierarchy: [NodeEntity]
    ) {
        nodeHierarchy.forEach { node in
            guard let intermediateVC = factory.buildBare(
                parentNode: node,
                config: .init(displayMode: .cloudDrive)
            ) else {
                return
            }
            intermediateVC.navigationItem.backButtonTitle = ""
            navigationController.addChild(intermediateVC)
        }
    }

    private func pushCloudDriveViewController(
        _ node: NodeEntity?,
        in navigationController: UINavigationController,
        using factory: CloudDriveViewControllerFactory,
        isInRubbishBin: Bool
    ) {
        let displayMode: DisplayMode = isInRubbishBin ? .rubbishBin : .cloudDrive
        
        guard let node, let lastVC = factory.buildBare(
            parentNode: node,
            config: .init(displayMode: displayMode)
        ) else {
            return
        }
        lastVC.navigationItem.backButtonTitle = ""
        navigationController.pushViewController(lastVC, animated: false)
    }
    
    private func resetCurrentNavigationController() {
        guard let navigationController else { return }
        
        navigationController.popToRootViewController(animated: false)
    }
    
    private func cancelRootSearchIfNeeded(in navigationController: UINavigationController) {
        guard let viewController = navigationController.viewControllers.first as? NewCloudDriveViewController else {
            return
        }
        viewController.cancelActiveSearch()
    }
    
    func navigateThroughNodeHierarchyAndPresent(_ node: NodeEntity) {
        node.toMEGANode(in: MEGASdk.shared)?.newNavigateToParentAndPresent()
    }
}
