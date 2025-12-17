import AsyncAlgorithms
import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAFoundation
import Search

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
    private var sortingPreferenceNotificationTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
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
    private let notificationCenter: NotificationCenter
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Debouncer
    private static let REQUESTS_DELAY: TimeInterval = 0.35
    private let debouncer = Debouncer(delay: REQUESTS_DELAY)
    private var monitorTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    private var subscriptions = Set<AnyCancellable>()
    private let tracker: any AnalyticsTracking
    private let sortOptionsViewModel: SearchResultsSortOptionsViewModel
    private var sortHeaderViewTapEventsTask: Task<Void, Never>?

    private var currentSortOrder: MEGADomain.SortOrderEntity {
        get {
            Helper.sortType(for: nil).toSortOrderEntity()
        }
        set {
            triggerEvent(for: newValue)
            Helper.save(newValue.toMEGASortOrderType(), for: nil)
        }
    }

    private lazy var sortHeaderCoordinator: SearchResultsSortHeaderCoordinator = {
        .init(
            sortOptionsViewModel: sortOptionsViewModel,
            currentSortOrderProvider: { Helper.sortType(for: nil).toSortOrderEntity().toSearchSortOrderEntity() },
            sortOptionSelectionHandler: { @MainActor [weak self] sortOption in
                guard let self else { return }
                currentSortOrder = sortOption.sortOrder.toDomainSortOrderEntity()
                invokeCommand?(.sortTypeHasChanged)
            }
        )
    }()

    var sortHeaderViewModel: SearchResultsHeaderSortViewViewModel {
        sortHeaderCoordinator.headerViewModel
    }

    lazy var viewModeHeaderViewModel: SearchResultsHeaderViewModeViewModel = {
        SearchResultsHeaderViewModeViewModel(
            selectedViewMode: viewTypePreference == .list ? .list : .grid,
            availableViewModes: [.list, .grid]
        )
    }()

    // MARK: - Initializer
    required init(
        explorerType: ExplorerTypeEntity,
        router: FilesExplorerRouter,
        useCase: some FilesSearchUseCaseProtocol,
        nodeDownloadUpdatesUseCase: some NodeDownloadUpdatesUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        createContextMenuUseCase: some CreateContextMenuUseCaseProtocol,
        nodeProvider: some MEGANodeProviderProtocol,
        sortOptionsViewModel: SearchResultsSortOptionsViewModel,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        notificationCenter: NotificationCenter = .default,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.explorerType = explorerType
        self.router = router
        self.useCase = useCase
        self.createContextMenuUseCase = createContextMenuUseCase
        self.nodeDownloadUpdatesUseCase = nodeDownloadUpdatesUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.nodeProvider = nodeProvider
        self.sortOptionsViewModel = sortOptionsViewModel
        self.featureFlagProvider = featureFlagProvider
        self.notificationCenter = notificationCenter
        self.tracker = tracker

        listenToViewModeChanges()
        listenToSortButtonPressedEvents()
    }
    
    deinit {
        monitorTask?.cancel()
        searchTask?.cancel()
        nodeDownloadCompletionMonitoringTask?.cancel()
        sortingPreferenceNotificationTask?.cancel()
        sortHeaderViewTapEventsTask?.cancel()
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
            subscribeToSortingPreferenceNotification()
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
                searchTag: text?.removingFirstLeadingHash(),
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
    
    private func subscribeToSortingPreferenceNotification() {
        sortingPreferenceNotificationTask = Task { [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: .sortingPreferenceChanged).map({ _ in () }) {
                self?.invokeCommand?(.sortTypeHasChanged)
                self?.configureContextMenus()
            }
        }
    }

    func getExplorerType() -> ExplorerTypeEntity {
        self.explorerType
    }

    private func triggerEvent(for sortOrder: MEGADomain.SortOrderEntity) {
        let eventIdentifier: (any EventIdentifier)? =  switch sortOrder {
        case .defaultAsc, .defaultDesc: SortByNameMenuItemEvent()
        case .sizeAsc, .sizeDesc: SortBySizeMenuItemEvent()
        case .creationAsc, .creationDesc: SortByDateAddedMenuItemEvent()
        case .modificationAsc, .modificationDesc: SortByDateModifiedMenuItemEvent()
        case .labelAsc, .labelDesc: SortByLabelMenuItemEvent()
        case .favouriteAsc, .favouriteDesc: SortByFavouriteMenuItemEvent()
        default: nil
        }
        guard let eventIdentifier else { return }
        tracker.trackAnalyticsEvent(with: eventIdentifier)
    }

    private func triggerEvent(for preference: ViewTypePreference) {
        tracker.trackAnalyticsEvent(with: preference == .list ? ViewModeListMenuItemEvent() : ViewModeGridMenuItemEvent())
    }

    private func listenToViewModeChanges() {
        viewModeHeaderViewModel
            .$selectedViewMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] in
                guard let self else { return }
                triggerEvent(for: $0 == .list ? .list : .grid)
            }
            .store(in: &subscriptions)
    }

    private func listenToSortButtonPressedEvents() {
        sortHeaderViewTapEventsTask = Task { [weak self, sortHeaderViewModel] in
            for await _ in sortHeaderViewModel.tapEvents {
                self?.tracker.trackAnalyticsEvent(with: SortButtonPressedEvent())
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
