import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

enum CloudDriveAction: ActionType {
    case updateEditModeActive(Bool)
    case updateSortType(SortOrderType)
    case updateParentNode(MEGANode)
    case moveToRubbishBin([MEGANode])
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
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let shouldDisplayMediaDiscoveryWhenMediaOnly: Bool
    private var parentNode: MEGANode?
    private let moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol
    
    init(parentNode: MEGANode?,
         shareUseCase: some ShareUseCaseProtocol,
         sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
         moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol
    ) {
        self.parentNode = parentNode
        self.shareUseCase = shareUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.featureFlagProvider = featureFlagProvider
        self.moveToRubbishBinViewModel = moveToRubbishBinViewModel
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
    
    func isParentMarkedAsSensitive(forDisplayMode displayMode: DisplayMode, isFromSharedItem: Bool) -> Bool? {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              isFromSharedItem == false,
              displayMode == .cloudDrive,
              parentNode?.isFolder() == true else {
            return nil
        }
        return parentNode?.isMarkedSensitive
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
        }
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
