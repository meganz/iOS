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
    
    init(
        navigationController: UINavigationController?,
        notificationsUseCase: some NotificationsUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        imageLoader: some ImageLoadingProtocol
    ) {
        self.navigationController = navigationController
        self.notificationsUseCase = notificationsUseCase
        self.nodeUseCase = nodeUseCase
        self.imageLoader = imageLoader
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
        
        guard
            mainTBC.children.count > mainTBC.selectedIndex,
            let navigationController = mainTBC.children[mainTBC.selectedIndex] as? UINavigationController
        else {
            return
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
            mainTBC.selectedIndex = TabType.cloudDrive.rawValue
        } else {
            mainTBC.selectedIndex = TabType.sharedItems.rawValue
            selectSharedSegmentIfNeeded(in: mainTBC)
        }
    }
    
    private func selectSharedSegmentIfNeeded(in mainTBC: MainTabBarController) {
        if let sharedNav = mainTBC.children[TabType.sharedItems.rawValue] as? UINavigationController,
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
        node.toMEGANode(in: MEGASdk.shared)?.navigateToParentAndPresent()
    }
}
