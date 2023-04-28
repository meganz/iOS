import MEGAFoundation
import MEGADomain
import MEGAPresentation
import MEGAData

enum FilesExplorerAction: ActionType {
    case onViewReady
    case startSearching(String?)
    case didSelectNode(MEGANode, [MEGANode])
    case didChangeViewMode(Int)
    case downloadNode(MEGANode)
}

final class FilesExplorerViewModel {
    
    enum Command: CommandType {
        case reloadNodes(nodes: [MEGANode]?, searchText: String?)
        case onNodesUpdate([MEGANode])
        case reloadData
        case setViewConfiguration(FilesExplorerViewConfiguration)
        case onTransferCompleted(MEGANode)
        case updateContextMenu(UIMenu)
        case updateUploadAddMenu(UIMenu)
        case sortTypeHasChanged
        case editingModeStatusChanges
        case viewTypeHasChanged
        case didSelect(UploadAddActionEntity)
    }
    
    private enum ViewTypePreference {
        case list
        case grid
    }
    
    private let router: FilesExplorerRouter
    private let useCase: FilesSearchUseCaseProtocol?
    private let favouritesUseCase: FavouriteNodesUseCaseProtocol?
    private let filesDownloadUseCase: FilesDownloadUseCase
    private let nodeClipboardOperationUseCase: NodeClipboardOperationUseCase
    private let createContextMenuUseCase: CreateContextMenuUseCaseProtocol
    private let explorerType: ExplorerTypeEntity
    private var contextMenuManager: ContextMenuManager?
    private var viewConfiguration: FilesExplorerViewConfiguration {
        switch explorerType {
        case .document:
            return DocumentExplorerViewConfiguration()
        case .audio:
            return AudioExploreViewConfiguration()
        case .video:
            return VideoExplorerViewConfiguration()
        case .favourites:
            return FavouritesExplorerViewConfiguration()
        }
    }
    
    private var viewTypePreference: ViewTypePreference = .list
    private var configForDisplayMenu: CMConfigEntity?
    private var configForUploadAddMenu: CMConfigEntity?
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Debouncer
    private static let REQUESTS_DELAY: TimeInterval = 0.35
    private let debouncer = Debouncer(delay: REQUESTS_DELAY)
    
    // MARK: - Initializer
    required init(explorerType: ExplorerTypeEntity,
                  router: FilesExplorerRouter,
                  useCase: FilesSearchUseCaseProtocol?,
                  favouritesUseCase: FavouriteNodesUseCaseProtocol?,
                  filesDownloadUseCase: FilesDownloadUseCase,
                  nodeClipboardOperationUseCase: NodeClipboardOperationUseCase,
                  createContextMenuUseCase: CreateContextMenuUseCaseProtocol) {
        self.explorerType = explorerType
        self.router = router
        self.useCase = useCase
        self.favouritesUseCase = favouritesUseCase
        self.nodeClipboardOperationUseCase = nodeClipboardOperationUseCase
        self.createContextMenuUseCase = createContextMenuUseCase
        self.filesDownloadUseCase = filesDownloadUseCase

        self.useCase?.onNodesUpdate { [weak self] nodes in
            guard let self = self else { return }
            self.debouncer.start {
                self.invokeCommand?(.reloadData)
            }
        }
        
        self.favouritesUseCase?.registerOnNodesUpdate { [weak self] nodes in
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
    
    private func configureContextMenus() {
        if explorerType == .document {
            contextMenuManager = ContextMenuManager(displayMenuDelegate: self, uploadAddMenuDelegate: self, createContextMenuUseCase: createContextMenuUseCase)
            
            configForUploadAddMenu = CMConfigEntity(menuType: .menu(type: .uploadAdd),
                                                    isDocumentExplorer: explorerType == .document)
            
            guard let configForUploadAddMenu,
                  let menu = contextMenuManager?.contextMenu(with: configForUploadAddMenu) else { return }
            
            invokeCommand?(.updateUploadAddMenu(menu))
        } else {
            contextMenuManager = ContextMenuManager(displayMenuDelegate: self, createContextMenuUseCase: createContextMenuUseCase)
        }
        
        configForDisplayMenu = CMConfigEntity(menuType: .menu(type: .display),
                                              viewMode: viewTypePreference == .list ? .list : .thumbnail,
                                              sortType: Helper.sortType(for: nil).toSortOrderEntity(),
                                              isFavouritesExplorer: explorerType == .favourites,
                                              isDocumentExplorer: explorerType == .document,
                                              isAudiosExplorer: explorerType == .audio,
                                              isVideosExplorer: explorerType == .video)
        
        guard let configForDisplayMenu,
              let menu = contextMenuManager?.contextMenu(with: configForDisplayMenu) else { return }
        
        invokeCommand?(.updateContextMenu(menu))
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: FilesExplorerAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.setViewConfiguration(viewConfiguration))
            configureContextMenus()
        case .startSearching(let text):
            startSearching(text)
        case .didSelectNode(let node, let allNodes):
            didSelect(node: node, allNodes: allNodes)
        case .didChangeViewMode(let viewType):
            viewTypePreference = ViewModePreference(rawValue: viewType) == .thumbnail ? .grid : .list
            configureContextMenus()
        case .downloadNode(let node):
            router.showDownloadTransfer(node: node)
        }
    }
    
    // MARK: search
    private func startSearching(_ text: String?) {
        guard explorerType != .favourites else {
            startSearchingFavouriteNodes(text)
            return
        }
        
        useCase?.search(string: text,
                       parent: nil,
                       supportCancel: true,
                       sortOrderType: SortOrderType.defaultSortOrderType(forNode: nil).toSortOrderEntity(),
                       cancelPreviousSearchIfNeeded: true) { [weak self] nodes, isCancelled in
            DispatchQueue.main.async {
                guard let self = self, !isCancelled else { return }
                
                let megaNodes = nodes?.toMEGANodes(in: MEGASdkManager.sharedMEGASdk())
                self.updateListenerForFilesDownload(withNodes: megaNodes)
                self.invokeCommand?(.reloadNodes(nodes: megaNodes, searchText: text))
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
    
    //MARK: Favourites
    private func startSearchingFavouriteNodes(_ text: String?) {
        favouritesUseCase?.allFavouriteNodes(searchString: text) { [weak self] result in
            switch result {
            case .success(let nodes):
                let nodeList = nodes.toMEGANodes(in: MEGASdkManager.sharedMEGASdk())
                self?.updateListenerForFilesDownload(withNodes: nodeList)
                self?.invokeCommand?(.reloadNodes(nodes: nodeList, searchText: text))
            case .failure(_):
                MEGALogError("Error getting all favourites nodes")
            }
        }
    }
}

extension FilesExplorerViewModel: DisplayMenuDelegate, UploadAddMenuDelegate {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            invokeCommand?(.editingModeStatusChanges)
        case .thumbnailView, .listView:
            if viewTypePreference == .list && action == .thumbnailView ||
                viewTypePreference == .grid && action == .listView {
                invokeCommand?(.viewTypeHasChanged)
            }
        default: break
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        Helper.save(sortType.megaSortOrderType, for: nil)
        invokeCommand?(.sortTypeHasChanged)
        configureContextMenus()
    }
    
    func uploadAddMenu(didSelect action: UploadAddActionEntity) {
        invokeCommand?(.didSelect(action))
    }
}
