

struct PhotosExplorerRouter {
    private weak var navigationController: UINavigationController?
    private let explorerType: ExplorerTypeEntity
    
    init(navigationController: UINavigationController?, explorerType: ExplorerTypeEntity) {
        self.navigationController = navigationController
        self.explorerType = explorerType
    }
    
    func start() {
        guard let navController = navigationController else {
            MEGALogDebug("Unable to start Document Explorer screen as navigation controller is nil")
            return
        }
        
        let sdk = MEGASdkManager.sharedMEGASdk()
        let nodesUpdateListenerRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let fileSearchRepo = SDKFilesSearchRepository(sdk: sdk)
        let useCase = FilesSearchUseCase(repo: fileSearchRepo,
                                         explorerType: explorerType,
                                         nodesUpdateListenerRepo: nodesUpdateListenerRepo)
        let viewModel = PhotoExplorerViewModel(router: self, useCase: useCase)
        let vc = PhotosExplorerViewController(viewModel: viewModel)
        navController.pushViewController(vc, animated: true)
    }
    
    func didSelect(node: MEGANode, allNodes: [MEGANode]) {
        NodeOpener(navigationController: navigationController).openNode(node, allNodes: allNodes)
    }
}

