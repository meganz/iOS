

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
        let nodeClipboardOperationRepo = SDKNodeClipboardOperationRepository(sdk: sdk)
        let fileSearchUseCase = FilesSearchUseCase(repo: fileSearchRepo,
                                                   explorerType: explorerType,
                                                   nodesUpdateListenerRepo: nodesUpdateListenerRepo)
        let nodeClipboardOperationUseCase = NodeClipboardOperationUseCase(repo: nodeClipboardOperationRepo)
        let viewModel = PhotoExplorerViewModel(router: self,
                                               fileSearchUseCase: fileSearchUseCase,
                                               nodeClipboardOperationUseCase: nodeClipboardOperationUseCase)
        let vc = PhotosExplorerViewController(viewModel: viewModel)
        navController.pushViewController(vc, animated: true)
    }
    
    func didSelect(node: MEGANode, allNodes: [MEGANode]) {
        NodeOpener(navigationController: navigationController).openNode(node, allNodes: allNodes)
    }
}

