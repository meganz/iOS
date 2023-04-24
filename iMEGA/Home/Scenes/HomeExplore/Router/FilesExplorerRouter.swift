import MEGADomain
import MEGAData

struct FilesExplorerRouter {
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
        let transferListenerRepo = SDKTransferListenerRepository(sdk: sdk)
        let fileSearchRepo = FilesSearchRepository(sdk: sdk)
        let clipboardOperationRepo = SDKNodeClipboardOperationRepository(sdk: sdk)
        let useCase = FilesSearchUseCase(repo: fileSearchRepo,
                                         nodeFormat: explorerType.toNodeFormatEntity(),
                                         nodesUpdateListenerRepo: nodesUpdateListenerRepo)
        let nodeClipboardOperationUseCase = NodeClipboardOperationUseCase(repo: clipboardOperationRepo)
        let fileDownloadUseCase = FilesDownloadUseCase(repo: transferListenerRepo)
        let createContextMenuUseCase = CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        let favouriteRepository = FavouriteNodesRepository.newRepo
        let favouritesUseCase = FavouriteNodesUseCase(repo: favouriteRepository)
        
        let viewModel = FilesExplorerViewModel(explorerType: explorerType,
                                               router: self,
                                               useCase: useCase,
                                               favouritesUseCase: favouritesUseCase,
                                               filesDownloadUseCase: fileDownloadUseCase,
                                               nodeClipboardOperationUseCase: nodeClipboardOperationUseCase,
                                               createContextMenuUseCase: createContextMenuUseCase)
        let preference: FilesExplorerContainerViewController.ViewPreference = explorerType == .video ? .list : .both
        let vc = FilesExplorerContainerViewController(viewModel: viewModel,
                                                      viewPreference: preference)
        navController.pushViewController(vc, animated: true)
    }
    
    func didSelect(node: MEGANode, allNodes: [MEGANode]) {
        NodeOpener(navigationController: navigationController).openNode(node, allNodes: allNodes)
    }
    
    func showDownloadTransfer(node: MEGANode) {
        guard let navigationController = navigationController else {
            return
        }
        
        let transfer = CancellableTransfer(handle: node.handle, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .download)
        CancellableTransferRouter(presenter: navigationController, transfers: [transfer], transferType: .download).start()
    }
}
