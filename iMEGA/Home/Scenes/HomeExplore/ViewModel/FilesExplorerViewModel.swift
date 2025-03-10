import AsyncAlgorithms
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

@MainActor
final class FilesExplorerViewModel: ViewModelType {
    
    enum Command: CommandType {
        case reloadNodes(nodes: [MEGANode], searchText: String?)
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
    private let nodeDownloadUpdatesUseCase: any NodeDownloadUpdatesUseCaseProtocol
    private let createContextMenuUseCase: any CreateContextMenuUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let explorerType: ExplorerTypeEntity
    private var contextMenuManager: ContextMenuManager?
    private let nodeProvider: any MEGANodeProviderProtocol
    private var nodeDownloadCompletionMonitoringTask: Task<Void, Never>? {
        willSet {
            nodeDownloadCompletionMonitoringTask?.cancel()
        }
    }
    
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var viewConfiguration: (any FilesExplorerViewConfiguration)? {
        switch explorerType {
        case .allDocs:
            return DocumentExplorerViewConfiguration()
        case .audio:
            return AudioExploreViewConfiguration()
        case .video:
            assert(false, "Invalid viewConfiguration for: \(explorerType)")
            return nil
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
                  nodeDownloadUpdatesUseCase: some NodeDownloadUpdatesUseCaseProtocol,
                  sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
                  createContextMenuUseCase: some CreateContextMenuUseCaseProtocol,
                  nodeProvider: some MEGANodeProviderProtocol,
                  featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.explorerType = explorerType
        self.router = router
        self.useCase = useCase
        self.createContextMenuUseCase = createContextMenuUseCase
        self.nodeDownloadUpdatesUseCase = nodeDownloadUpdatesUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.nodeProvider = nodeProvider
        self.featureFlagProvider = featureFlagProvider
    }
    
    deinit {
        monitorTask?.cancel()
        searchTask?.cancel()
        nodeDownloadCompletionMonitoringTask?.cancel()
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
            guard let viewConfiguration else { return }
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
    private func monitorNodeUpdates() async {
        for await _ in useCase.nodeUpdates {
            debouncer.start { @MainActor [weak self] in
                self?.invokeCommand?(.reloadData)
            }
        }
    }
    
    private func startSearching(_ text: String?) async {
        do {
            let nodes: [NodeEntity] = try await startSearch(
                text: text,
                formatType: explorerType.toNodeFormatEntity(),
                favouritesOnly: explorerType == .favourites)
            
            let megaNodes = await toMEGANode(from: nodes)
            updateListenerForFilesDownload(withNodes: nodes)
            invokeCommand?(.reloadNodes(nodes: megaNodes, searchText: text))
        } catch is CancellationError, NodeSearchResultErrorEntity.cancelled {
            MEGALogError("[Files Explorer] startSearching cancelled for type:\(explorerType)")
        } catch {
            MEGALogError("[Files Explorer] Error getting all nodes for type:\(explorerType)")
        }
    }
    
    private func startSearch(text: String?, formatType: NodeFormatEntity, favouritesOnly: Bool = false) async throws -> [NodeEntity] {
        try await useCase.search(
            filter: .recursive(
                searchText: text,
                searchDescription: text,
                searchTag: featureFlagProvider.isFeatureFlagEnabled(for: .searchByNodeTags) ? text?.removingFirstLeadingHash() : nil,
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: true,
                sortOrderType: SortOrderType.defaultSortOrderType(forNode: nil).toSortOrderEntity(),
                formatType: explorerType.toNodeFormatEntity(),
                sensitiveFilterOption: await sensitiveDisplayPreferenceUseCase.excludeSensitives() ? .nonSensitiveOnly : .disabled,
                favouriteFilterOption: favouritesOnly ? .onlyFavourites : .disabled,
                useAndForTextQuery: false
            ),
            cancelPreviousSearchIfNeeded: true
        )
    }
    	
    private func toMEGANode(from nodes: [NodeEntity]) async -> [MEGANode] {
        await nodes
            .async
            .compactMap { await self.nodeProvider.node(for: $0.handle) }
            .reduce(into: [], { @Sendable in $0.append($1) })
	}
    
    private func didSelect(node: MEGANode, allNodes: [MEGANode]) {
        router.didSelect(node: node, allNodes: allNodes)
    }
    
    private func updateListenerForFilesDownload(withNodes nodes: [NodeEntity]) {
        nodeDownloadCompletionMonitoringTask = Task { [weak self, nodeDownloadUpdatesUseCase] in
            for await node in nodeDownloadUpdatesUseCase.startMonitoringDownloadCompletion(for: nodes) {
                guard let megaNode = await self?.nodeProvider.node(for: node.handle) else { continue }
                self?.invokeCommand?(.onTransferCompleted(megaNode))
            }
        }
    }
    
    func getExplorerType() -> ExplorerTypeEntity {
        self.explorerType
    }
}

extension FilesExplorerViewModel: DisplayMenuDelegate, UploadAddMenuDelegate {
    nonisolated func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        Task { @MainActor in
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
    }
    
    nonisolated func sortMenu(didSelect sortType: SortOrderType) {
        Task { @MainActor in
            Helper.save(sortType.megaSortOrderType, for: nil)
            invokeCommand?(.sortTypeHasChanged)
            configureContextMenus()
        }
    }
    
    nonisolated func uploadAddMenu(didSelect action: UploadAddActionEntity) {
        Task { @MainActor in
            invokeCommand?(.didSelect(action))
        }
    }
}
