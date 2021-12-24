
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
    
    // MARK: - Debouncer
    private static let REQUESTS_DELAY: TimeInterval = 0.35
    private let debouncer = Debouncer(delay: REQUESTS_DELAY)
    
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
            self.debouncer.start {
                self.invokeCommand?(.reloadData)
            }
        }
        
        self.nodeClipboardOperationUseCase.onNodeMove { [weak self] node in
            self?.invokeCommand?(.onNodesUpdate([node]))
        }
        
        self.nodeClipboardOperationUseCase.onNodeCopy { [weak self] _ in
            guard let self = self else { return }
            self.debouncer.start {
                self.invokeCommand?(.reloadData)
            }
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
                       cancelPreviousSearchIfNeeded: true) { [weak self] nodes, isCancelled in
            DispatchQueue.main.async {
                guard let self = self, !isCancelled else { return }
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
            self.invokeCommand?(.onTransferCompleted(node))
        }
    }
    
    func getExplorerType() -> ExplorerTypeEntity {
        return self.explorerType
    }
}
