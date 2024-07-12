import MEGADomain
import MEGAFoundation
import MEGAPresentation
import MEGASDKRepo

enum FilesExplorerAction: ActionType {
    case onViewReady
    case startSearching(String?)
    case didSelectNode(MEGANode, [MEGANode])
    case didChangeViewMode(Int)
    case downloadNode(MEGANode)
}

final class FilesExplorerViewModel: ViewModelType {
    
    enum Command: CommandType {
        case reloadNodes(nodes: [MEGANode], searchText: String?)
        case onNodesUpdate([MEGANode])
        case reloadData
        case setViewConfiguration(any FilesExplorerViewConfiguration)
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
    private let useCase: any FilesSearchUseCaseProtocol
    private let filesDownloadUseCase: FilesDownloadUseCase
    private let nodeClipboardOperationUseCase: NodeClipboardOperationUseCase
    private let createContextMenuUseCase: any CreateContextMenuUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let explorerType: ExplorerTypeEntity
    private var contextMenuManager: ContextMenuManager?
    private let nodeProvider: any MEGANodeProviderProtocol
    
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var viewConfiguration: any FilesExplorerViewConfiguration {
        switch explorerType {
        case .allDocs:
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
    private var monitorTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    // MARK: - Initializer
    required init(explorerType: ExplorerTypeEntity,
                  router: FilesExplorerRouter,
                  useCase: some FilesSearchUseCaseProtocol,
                  filesDownloadUseCase: FilesDownloadUseCase,
                  nodeClipboardOperationUseCase: NodeClipboardOperationUseCase,
                  contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
                  createContextMenuUseCase: some CreateContextMenuUseCaseProtocol,
                  nodeProvider: some MEGANodeProviderProtocol,
                  featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.explorerType = explorerType
        self.router = router
        self.useCase = useCase
        self.nodeClipboardOperationUseCase = nodeClipboardOperationUseCase
        self.createContextMenuUseCase = createContextMenuUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.filesDownloadUseCase = filesDownloadUseCase
        self.nodeProvider = nodeProvider
        self.featureFlagProvider = featureFlagProvider
                        
        self.nodeClipboardOperationUseCase.onNodeMove { [weak self] node in
            self?.invokeCommand?(.onNodesUpdate([node]))
        }
        
        self.nodeClipboardOperationUseCase.onNodeCopy { [weak self] _ in
            guard let self else { return }
            self.debouncer.start {
                self.invokeCommand?(.reloadData)
            }
        }
    }
    
    deinit {
        monitorTask?.cancel()
        searchTask?.cancel()
    }
    
    private func configureContextMenus() {
        if explorerType == .allDocs {
            contextMenuManager = ContextMenuManager(displayMenuDelegate: self, uploadAddMenuDelegate: self, createContextMenuUseCase: createContextMenuUseCase)
            
            configForUploadAddMenu = CMConfigEntity(menuType: .menu(type: .uploadAdd),
                                                    isDocumentExplorer: explorerType == .allDocs)
            
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
                                              isDocumentExplorer: explorerType == .allDocs,
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
            monitorTask = Task { await monitorNodeUpdates() }
        case .startSearching(let text):
            searchTask = Task { await startSearching(text) }
        case .didSelectNode(let node, let allNodes):
            didSelect(node: node, allNodes: allNodes)
        case .didChangeViewMode(let viewType):
            viewTypePreference = ViewModePreferenceEntity(rawValue: viewType) == .thumbnail ? .grid : .list
            configureContextMenus()
        case .downloadNode(let node):
            router.showDownloadTransfer(node: node)
        }
    }
    
    // MARK: search
    @MainActor
    private func monitorNodeUpdates() async {
        for await _ in useCase.nodeUpdates {
            debouncer.start { @MainActor [weak self] in
                self?.invokeCommand?(.reloadData)
            }
        }
    }
    
    @MainActor
    private func startSearching(_ text: String?) async {
        do {
            let nodes: [NodeEntity] = try await startSearch(
                text: text,
                formatType: explorerType.toNodeFormatEntity(),
                favouritesOnly: explorerType == .favourites)
            
            let megaNodes = await toMEGANode(from: nodes)
            updateListenerForFilesDownload(withNodes: megaNodes)
            invokeCommand?(.reloadNodes(nodes: megaNodes, searchText: text))
        } catch is CancellationError, NodeSearchResultErrorEntity.cancelled {
            MEGALogError("[Files Explorer] startSearching cancelled for type:\(explorerType)")
        } catch {
            MEGALogError("[Files Explorer] Error getting all nodes for type:\(explorerType)")
        }
    }
    
    private func shouldExcludeHiddenSensitive() async -> Bool {
        if featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) {
            await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        } else {
            false
        }
    }
    
    private func startSearch(text: String?, formatType: NodeFormatEntity, favouritesOnly: Bool = false) async throws -> [NodeEntity] {
        try await useCase.search(
            filter: .recursive(
                searchText: text,
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: true,
                sortOrderType: SortOrderType.defaultSortOrderType(forNode: nil).toSortOrderEntity(),
                formatType: explorerType.toNodeFormatEntity(),
                sensitiveFilterOption: await shouldExcludeHiddenSensitive() ? .nonSensitiveOnly : .disabled,
                favouriteFilterOption: favouritesOnly ? .onlyFavourites : .disabled),
            cancelPreviousSearchIfNeeded: true)
    }
    	
    private func toMEGANode(from nodes: [NodeEntity]) async -> [MEGANode] {
        await withTaskGroup(of: (Int, MEGANode?).self, returning: [MEGANode].self) { taskGroup in
            let nodeProvider = self.nodeProvider
            for (index, node) in nodes.enumerated() {
                _ = taskGroup.addTaskUnlessCancelled { (index, await nodeProvider.node(for: node.handle)) }
            }
            return await taskGroup
                .reduce(into: Array(repeating: Optional<MEGANode>.none, count: nodes.count)) { $0[$1.0] = $1.1 }
                .compactMap { $0 }
        }
	}
    
    private func didSelect(node: MEGANode, allNodes: [MEGANode]) {
        router.didSelect(node: node, allNodes: allNodes)
    }
    
    private func updateListenerForFilesDownload(withNodes nodes: [MEGANode]?) {
        filesDownloadUseCase.addListener(nodes: nodes) { [weak self] node in
            
            guard let self else { return }
            self.invokeCommand?(.onTransferCompleted(node))
        }
    }
    
    func getExplorerType() -> ExplorerTypeEntity {
        self.explorerType
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
