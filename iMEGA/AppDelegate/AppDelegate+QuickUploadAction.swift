import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

extension AppDelegate {
    
    @objc func handleQuickUploadAction() {
        mainTBC?.selectedIndex = TabManager.driveTabIndex()
        guard let navigationController = mainTBC?.selectedViewController as? UINavigationController,
                let cdViewController = navigationController.viewControllers.first as? NewCloudDriveViewController else {
            assertionFailure("The first tabbar VC must be a NewCloudDriveViewController")
            return
        }
        
        let router = buildRouter(
            navigationController: navigationController,
            viewModeProvider: cdViewController.viewModeProvider.viewMode
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
