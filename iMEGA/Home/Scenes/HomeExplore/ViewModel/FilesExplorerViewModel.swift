
enum FilesExplorerAction: ActionType {
    case onViewReady
    case startSearching(String?)
    case didSelectNode(MEGANode, [MEGANode])
}

final class FilesExplorerViewModel {
    
    enum Command: CommandType {
        case reloadNodes(nodes: [MEGANode]?, searchText: String?)
        case onNodesUpdate([MEGANode])
        case reloadData
        case setViewConfiguration(FilesExplorerViewConfiguration)
        case onTransferStarted(MEGANode)
        case onProgressUpdate(_ progress: Float, _ node: MEGANode, _ infoString: String)
        case onTransferCompleted(MEGANode)
    }
    
    private enum ViewTypePreference {
        case list
        case grid
    }
    
    private let router: FilesExplorerRouter
    private let useCase: FilesSearchUseCaseProtocol
    private let filesDownloadUseCase: FilesDownloadUseCase
    private let nodeClipboardOperationUseCase: NodeClipboardOperationUseCase
    private let explorerType: ExplorerTypeEntity
    private var viewConfiguration: FilesExplorerViewConfiguration {
        switch explorerType {
        case .document:
            return DocumentExplorerViewConfiguration()
        case .audio:
            return AudioExploreViewConfiguration()
        case .video:
            return VideoExplorerViewConfiguration()
        default:
            fatalError("invalid configuration object")
        }
    }
    
    private var viewTypePreference: ViewTypePreference = .list
    
    var invokeCommand: ((Command) -> Void)?

    // MARK: - Initializer
    required init(explorerType: ExplorerTypeEntity,
                  router: FilesExplorerRouter,
                  useCase: FilesSearchUseCaseProtocol,
                  filesDownloadUseCase: FilesDownloadUseCase,
                  nodeClipboardOperationUseCase: NodeClipboardOperationUseCase) {
        self.explorerType = explorerType
        self.router = router
        self.useCase = useCase
        self.nodeClipboardOperationUseCase = nodeClipboardOperationUseCase
        self.filesDownloadUseCase = filesDownloadUseCase
        
        self.useCase.onNodesUpdate { [weak self] nodes in
            guard let self = self else { return }
            self.invokeCommand?(.reloadData)
        }
        
        self.nodeClipboardOperationUseCase.onNodeMove { [weak self] node in
            self?.invokeCommand?(.onNodesUpdate([node]))
        }
        
        self.nodeClipboardOperationUseCase.onNodeCopy { [weak self] _ in
            self?.invokeCommand?(.reloadData)
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: FilesExplorerAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.setViewConfiguration(viewConfiguration))
        case .startSearching(let text):
            startSearching(text)
        case .didSelectNode(let node, let allNodes):
            didSelect(node: node, allNodes: allNodes)
        }
    }
    
    // MARK: search
    private func startSearching(_ text: String?) {
        useCase.search(string: text,
                       inNode: nil,
                       sortOrderType: SortOrderType.defaultSortOrderType(forNode: nil).megaSortOrderType,
                       cancelPreviousSearchIfNeeded: true) { [weak self] nodes in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateListenerForFilesDownload(withNodes: nodes)
                self.invokeCommand?(.reloadNodes(nodes: nodes, searchText: text))
            }
        }
    }
    
    private func didSelect(node: MEGANode, allNodes: [MEGANode]) {
        router.didSelect(node: node, allNodes: allNodes)
    }
    
    private func updateListenerForFilesDownload(withNodes nodes: [MEGANode]?) {
        filesDownloadUseCase.addListener(nodes: nodes) { [weak self] node in
            
            guard let self = self else { return }
            self.invokeCommand?(.onTransferStarted(node))
            
        } progress: { [weak self] node, progress, speed in
            
            guard let self = self else { return }
            let percentageCompleted = String(format: "%.f%%", progress * 100)
            let speed = String(format: "%@/s", Helper.memoryStyleString(fromByteCount: speed))
            let infoString = String(format: "%@ • %@", percentageCompleted, speed)
            self.invokeCommand?(.onProgressUpdate(progress, node, infoString))

        } end: { [weak self] node in
            
            guard let self = self else { return }
            self.invokeCommand?(.onTransferCompleted(node))
        }
    }
}
