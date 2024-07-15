import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension AppDelegate {
    
    @objc func handleQuickUploadAction() {
        mainTBC?.selectedIndex = TabType.cloudDrive.rawValue
        guard let navigationController = mainTBC?.children.first as? UINavigationController else { return }
        
        guard UserDefaults.standard.bool(forKey: Helper.cloudDriveABTestCacheKey()) ||
                DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newCloudDrive),
        let newCloudDriveViewController = navigationController.viewControllers.first as? NewCloudDriveViewController else {
            guard let cdViewController = navigationController.viewControllers.first as? CloudDriveViewController else {
                assertionFailure("The first tabbar VC must be a CloudDriveViewController")
                return
            }
            
            cdViewController.presentUploadOptions()
            return
        }
        
        let router = buildRouter(
            navigationController: navigationController,
            viewModeProvider: newCloudDriveViewController.viewModeProvider.viewMode
        )
        // Needs to retain the router because it holds the dependencies (ContextMenuManager and delegate) that are needed for the Quicks Upload feature to work.
        quickUploadActionRouter = router
        router.start()
    }
    
    private func buildRouter(
        navigationController: UINavigationController,
        viewModeProvider: @escaping () -> ViewModePreferenceEntity?
    ) -> CloudDriveQuickUploadActionRouter {
        let nodeRepository = NodeRepository.newRepo
        let nodeRouter = HomeScreenFactory().makeRouter(navController: navigationController, tracker: DIContainer.tracker)
        let createContextMenuUseCase = CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        let nodeInsertionRouter = CloudDriveNodeInsertionRouter(navigationController: navigationController, openNodeHandler: { node in
            Task { @MainActor in
                nodeRouter.didTapNode(nodeHandle: node.handle)
            }
        })
        
        let uploadAddMenuDelegateHandler = UploadAddMenuDelegateHandler(
            tracker: DIContainer.tracker,
            nodeInsertionRouter: nodeInsertionRouter,
            nodeSource: .node({
                nodeRepository.rootNode() // Per existing logic, we only upload to the root folder of CD.
            })
        )
        
        let contextMenuManager = ContextMenuManager(
            uploadAddMenuDelegate: uploadAddMenuDelegateHandler,
            createContextMenuUseCase: createContextMenuUseCase
        )
        
        return .init(
            navigationController: navigationController,
            uploadAddMenuDelegateHandler: uploadAddMenuDelegateHandler,
            contextMenuManager: contextMenuManager,
            viewModeProvider: viewModeProvider
        )
    }
}
