import MEGAAppPresentation
import MEGADomain

@MainActor
protocol NodeNavigationRouting: Sendable {
    func navigateThroughNodeHierarchy(_ nodeHierarchy: [NodeEntity], isOwnNode: Bool, isInRubbishBin: Bool)
}

struct NodeNavigationRouter: NodeNavigationRouting {
    private var isNavigationRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)
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
        guard let presenter = mainTBC.selectedViewController as? (any SharedItemsPresenting) else {
            return assertionFailure("Trying to navigate to SharedItems screen but selected view controller is not of type SharedItemsPresenting")
        }
        presenter.showSharedItems()
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
        guard let mainTBC = UIApplication.mainTabBarRootViewController() as? MainTabBarController,
              let navigationController = mainTBC.children[mainTBC.selectedIndex] as? UINavigationController  else { return }
        
        navigationController.popToRootViewController(animated: false)
    }
    
    private func cancelRootSearchIfNeeded(in navigationController: UINavigationController) {
        guard let viewController = navigationController.viewControllers.first as? NewCloudDriveViewController else {
            return
        }
        viewController.cancelActiveSearch()
    }
}
