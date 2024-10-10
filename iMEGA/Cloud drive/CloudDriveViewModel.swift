import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

enum CloudDriveAction: ActionType {
    case updateEditModeActive(Bool)
    case updateSortType(SortOrderType)
    case updateParentNode(MEGANode)
    case moveToRubbishBin([MEGANode])
    case resetSensitivitySetting
    case didTapChooseFromPhotos
    case didTapImportFromFiles
    case didTapNewFolder
    case didTapNewTextFile
    case didOpenAddMenu
    case didTapHideNodes
}

@objc final class CloudDriveViewModel: NSObject, ViewModelType {
    
    enum Command: CommandType, Equatable {
        case enterSelectionMode
        case exitSelectionMode
        case reloadNavigationBarItems
        case updateSortedData
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    @objc private(set) var editModeActive = false
    var isSelectionHidden = false {
        didSet {
            invokeCommand?(.reloadNavigationBarItems)
        }
    }
    
    private let router = SharedItemsViewRouter()
    private let shareUseCase: any ShareUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let systemGeneratedNodeUseCase: any SystemGeneratedNodeUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let sdk: MEGASdk

    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let shouldDisplayMediaDiscoveryWhenMediaOnly: Bool
    private var parentNode: MEGANode?
    private let moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol
    private let nodeSensitivityChecker: any NodeSensitivityChecking

    private let tracker: any AnalyticsTracking
    
    private var sensitiveSettingTask: Task<Bool, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    init(parentNode: MEGANode?,
         shareUseCase: some ShareUseCaseProtocol,
         sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol,
         systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         tracker: some AnalyticsTracking,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
         moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol,
         nodeSensitivityChecker: some NodeSensitivityChecking,
         sdk: MEGASdk = MEGASdk.shared
    ) {
        self.parentNode = parentNode
        self.shareUseCase = shareUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.systemGeneratedNodeUseCase = systemGeneratedNodeUseCase
        self.accountUseCase = accountUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
        self.moveToRubbishBinViewModel = moveToRubbishBinViewModel
        self.sdk = sdk
        self.nodeSensitivityChecker = nodeSensitivityChecker
        shouldDisplayMediaDiscoveryWhenMediaOnly = preferenceUseCase[.shouldDisplayMediaDiscoveryWhenMediaOnly] ?? true
    }
    
    func openShareFolderDialog(forNodes nodes: [MEGANode]) {
        Task { @MainActor [shareUseCase] in
            do {
                _ = try await shareUseCase.createShareKeys(forNodes: nodes.toNodeEntities())
                router.showShareFoldersContactView(withNodes: nodes)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    @objc func shouldShowConfirmationAlert(forRemovedFiles fileCount: Int, andFolders folderCount: Int) -> Bool {
        return fileCount > 0 || folderCount > 0
    }
    
    @objc func alertMessage(forRemovedFiles fileCount: Int, andFolders folderCount: Int) -> String {
        return String.inject(plurals: [
            .init(count: fileCount, localize: Strings.Localizable.SharedItems.Rubbish.Warning.fileCount),
            .init(count: folderCount, localize: Strings.Localizable.SharedItems.Rubbish.Warning.folderCount)
        ], intoLocalized: Strings.Localizable.SharedItems.Rubbish.Warning.message)
    }
    
    @objc func alertTitle(forRemovedFiles fileCount: Int, andFolders folderCount: Int) -> String? {
        guard fileCount > 1 else { return nil }
        return Strings.Localizable.removeNodeFromRubbishBinTitle
    }
    
    @objc func shouldShowMediaDiscoveryAutomatically(forNodes nodes: MEGANodeList?) -> Bool {
        guard shouldDisplayMediaDiscoveryWhenMediaOnly,
              let nodes else {
            return false
        }
        return nodes.containsOnlyVisualMedia()
    }
    
    @objc func hasMediaFiles(nodes: MEGANodeList?) -> Bool {
        nodes?.containsVisualMedia() ?? false
    }
    
    @objc func shouldExcludeSensitiveItems() async -> Bool {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else {
            return false
        }
        if let sensitiveSettingTask {
            return await sensitiveSettingTask.value
        }
        let sensitiveSettingTask = Task { [weak self] in
            guard let self else { return false }
            return await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        }
        self.sensitiveSettingTask = sensitiveSettingTask
        return await sensitiveSettingTask.value
    }
    
    func isParentMarkedAsSensitive(forDisplayMode displayMode: DisplayMode, isFromSharedItem: Bool) async -> Bool? {
        await nodeSensitivityChecker.evaluateNodeSensitivity(
            for: .node({ [weak self] in self?.parentNode?.toNodeEntity() }),
            displayMode: displayMode,
            isFromSharedItem: isFromSharedItem
        )
    }
    
    func nodesForDisplayMode(_ displayMode: DisplayMode, sortOrder: MEGASortOrderType) async -> MEGANodeList? {
        guard let parentNode else { return nil }
        
        return switch displayMode {
        case .cloudDrive:
            nodesForParent(parentNode: parentNode, sortOrder: sortOrder,
                           shouldExcludeSensitive: await shouldExcludeSensitiveItems())
        case .rubbishBin, .backup:
            nodesForParent(parentNode: parentNode, sortOrder: sortOrder, shouldExcludeSensitive: false)
        default:
            nil
        }
    }
    
    func dispatch(_ action: CloudDriveAction) {
        switch action {
        case .updateEditModeActive(let isActive):
            update(editModeActive: isActive)
        case .updateSortType(let sortType):
            update(sortType: sortType)
        case .updateParentNode(let newParentNode):
            parentNode = newParentNode
            invokeCommand?(.reloadNavigationBarItems)
        case .moveToRubbishBin(let nodes):
            moveToRubbishBinViewModel.moveToRubbishBin(nodes: nodes.toNodeEntities())
        case .resetSensitivitySetting:
            guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else { return }
            sensitiveSettingTask = nil
        case .didTapChooseFromPhotos:
            trackChooseFromPhotosEvent()
        case .didTapImportFromFiles:
            trackImportFromFilesEvent()
        case .didTapNewFolder:
            trackNewFolderEvent()
        case .didTapNewTextFile:
            trackNewTextFileEvent()
        case .didOpenAddMenu:
            trackOpenAddMenuEvent()
        case .didTapHideNodes:
            trackHideNodeMenuEvent()
        }
    }
    
    private func trackChooseFromPhotosEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveChooseFromPhotosMenuToolbarEvent())
    }
    
    private func trackImportFromFilesEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveImportFromFilesMenuToolbarEvent())
    }
    
    private func trackNewFolderEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveNewFolderMenuToolbarEvent())
    }
    
    private func trackNewTextFileEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveNewTextFileMenuToolbarEvent())
    }
    
    private func trackOpenAddMenuEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveAddMenuEvent())
    }
    
    private func trackHideNodeMenuEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveHideNodeMenuItemEvent())
    }
    
    private func update(sortType: SortOrderType) {
        
        guard let parentNodeEntity = parentNode?.toNodeEntity() else {
            return
        }
        sortOrderPreferenceUseCase.save(sortOrder: sortType.toSortOrderEntity(), for: parentNodeEntity)
        invokeCommand?(.updateSortedData)
    }
    
    func sortOrder(for viewMode: ViewModePreferenceEntity) -> SortOrderType {
        let sortType = sortOrderPreferenceUseCase.sortOrder(for: parentNode?.toNodeEntity()).toSortOrderType()
        switch viewMode {
        case .perFolder, .list, .thumbnail:
            return sortType
        case .mediaDiscovery:
            return [.newest, .oldest].notContains(sortType) ? .newest : sortType
        }
    }
    
    // MARK: Edit Mode
    private func update(editModeActive: Bool) {
        guard self.editModeActive != editModeActive else {
            return
        }
        self.editModeActive = editModeActive
        invokeCommand?(editModeActive ? .enterSelectionMode : .exitSelectionMode)
    }
    
    // MARK: Node Retrieval
    
    private func nodesForParent(parentNode: MEGANode, sortOrder: MEGASortOrderType, shouldExcludeSensitive: Bool) -> MEGANodeList {
        let filter = makeSearchFilter(parentNodeHandle: parentNode.handle, excludeSensitive: shouldExcludeSensitive)
        let cancelToken = MEGACancelToken()
        MEGALogDebug("[Search] non recursively \(filter.term) in parent \(parentNode.base64Handle ?? "")")
        let nodeList = sdk.searchNonRecursively(with: filter,
                                                orderType: sortOrder,
                                                page: nil,
                                                cancelToken: cancelToken)
        MEGALogDebug("[Search] nodes found \(nodeList.size)")
        return nodeList
    }
    
    private func makeSearchFilter(parentNodeHandle: MEGAHandle, excludeSensitive: Bool) -> MEGASearchFilter {
        MEGASearchFilter(
            term: "",
            parentNodeHandle: parentNodeHandle,
            nodeType: .unknown,
            category: .unknown,
            sensitiveFilter: excludeSensitive ? MEGASearchFilterSensitiveOption.nonSensitiveOnly : .disabled,
            favouriteFilter: .disabled,
            creationTimeFrame: nil,
            modificationTimeFrame: nil
        )
    }
}

private extension MEGANodeList {
    var nodeCount: Int { size }
    
    func containsOnlyVisualMedia() -> Bool {
        self.toNodeListEntity().containsOnlyVisualMedia()
    }
    
    func containsVisualMedia() -> Bool {
        self.toNodeListEntity().containsVisualMedia()
    }
}

extension NodeListEntity {
    func containsVisualMedia() -> Bool {
        guard nodesCount > 0 else { return false }
        return (0..<nodesCount).contains {
            nodeAt($0)?.name.fileExtensionGroup.isVisualMedia ?? false
        }
    }
    
    func containsOnlyVisualMedia() -> Bool {
        guard nodesCount > 0 else { return false }
        return (0..<nodesCount).notContains {
            guard let nodeName = nodeAt($0)?.name else {
                return false
            }
            return !nodeName.fileExtensionGroup.isVisualMedia
        }
    }
}
