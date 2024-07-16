import MEGADomain
import MEGAL10n
import MEGASDKRepo

/// Factory mean to be used as a single point of creating CMConfigEntity inside new Cloud Drive (NodeBrowserView)
/// Previous implementation is sprinkled throughout CloudDriveViewController extensions and impossible to refactor out with high confidence
struct CloudDriveContextMenuConfigFactory {
    
    let backupsUseCase: any BackupsUseCaseProtocol
    let nodeUseCase: any NodeUseCaseProtocol
    
    func contextMenuConfiguration(
        parentNode: NodeEntity?,
        nodeAccessType: NodeAccessTypeEntity?,
        currentViewMode: ViewModePreferenceEntity,
        isSelectionHidden: Bool,
        showMediaDiscovery: Bool,
        sortOrder: SortOrderEntity,
        displayMode: DisplayMode,
        isFromViewInFolder: Bool,
        isHidden: Bool?
    ) -> CMConfigEntity? {
        
        guard
            let parentNode,
            let nodeAccessType
        else { return nil }
        
        if displayMode == .backup {
            return contextMenuBackupConfiguration(
                parentNode: parentNode,
                nodeAccessType: nodeAccessType,
                currentViewMode: currentViewMode,
                sortOrder: sortOrder,
                mediaDiscoveryEnabled: showMediaDiscovery,
                displayMode: displayMode,
                isFromViewInFolder: isFromViewInFolder
            )
        }
        
        if displayMode == .rubbishBin && !isRubbishRoot(node: parentNode) {
            return contextMenuRubbishBinConfiguration(
                parentNode: parentNode,
                currentViewMode: currentViewMode,
                sortOrder: sortOrder
            )
        }
        
        return defaultConfig(
            parentNode: parentNode,
            nodeAccessType: nodeAccessType,
            currentViewMode: currentViewMode,
            isSelectionHidden: isSelectionHidden,
            showMediaDiscovery: showMediaDiscovery,
            sortOrder: sortOrder,
            displayMode: displayMode,
            isFromViewInFolder: isFromViewInFolder,
            isHidden: isHidden
        )
    }
    
    private func contextMenuRubbishBinConfiguration(
        parentNode: NodeEntity,
        currentViewMode: ViewModePreferenceEntity,
        sortOrder: SortOrderEntity
    ) -> CMConfigEntity? {
        guard
            parentNode.isFolder,
            !isRubbishRoot(node: parentNode)
        else {
            return nil
        }
        
        return CMConfigEntity(
            menuType: .menu(type: .rubbishBin),
            viewMode: currentViewMode,
            sortType: sortOrder,
            isRubbishBinFolder: true,
            isRestorable: nodeUseCase.isRestorable(node: parentNode)
        )
    }
    
    private func defaultConfig(
        parentNode: NodeEntity,
        nodeAccessType: NodeAccessTypeEntity,
        currentViewMode: ViewModePreferenceEntity,
        isSelectionHidden: Bool,
        showMediaDiscovery: Bool,
        sortOrder: SortOrderEntity,
        displayMode: DisplayMode,
        isFromViewInFolder: Bool,
        isHidden: Bool?
    ) -> CMConfigEntity {
        .init(
            menuType: .menu(type: .display),
            viewMode: currentViewMode,
            accessLevel: nodeAccessType.toShareAccessLevel(),
            sortType: sortOrder,
            isAFolder: parentNode.nodeType != .root,
            isRubbishBinFolder: displayMode == .rubbishBin,
            isViewInFolder: isFromViewInFolder,
            isIncomingShareChild: isIncomingSharedRootChild(parentNode: parentNode, nodeAccessType: nodeAccessType),
            isSelectHidden: isSelectionHidden,
            isOutShare: parentNode.isOutShare,
            isExported: parentNode.isExported,
            showMediaDiscovery: showMediaDiscovery,
            isHidden: isHidden
        )
    }
    
    private func isIncomingSharedRootChild(
        parentNode: NodeEntity,
        nodeAccessType: NodeAccessTypeEntity
    ) -> Bool {
        nodeAccessType != .owner && nodeUseCase.parentForHandle(parentNode.handle) == nil
    }
    
    private func contextMenuBackupConfiguration(
        parentNode: NodeEntity,
        nodeAccessType: NodeAccessTypeEntity,
        currentViewMode: ViewModePreferenceEntity,
        sortOrder: SortOrderEntity,
        mediaDiscoveryEnabled: Bool,
        displayMode: DisplayMode,
        isFromViewInFolder: Bool
    ) -> CMConfigEntity? {
        .init(
            menuType: .menu(type: .display),
            viewMode: currentViewMode,
            accessLevel: nodeAccessType.toShareAccessLevelEntity(),
            sortType: sortOrder,
            isAFolder: parentNode.nodeType != .root,
            isRubbishBinFolder: displayMode == .rubbishBin,
            isViewInFolder: isFromViewInFolder,
            isIncomingShareChild: isIncomingSharedRootChild(parentNode: parentNode, nodeAccessType: nodeAccessType),
            isBackupsRootNode: isBackupsRoot(node: parentNode),
            isBackupsChild: isBackupsChild(node: parentNode),
            isOutShare: parentNode.isOutShare,
            isExported: parentNode.isExported,
            showMediaDiscovery: mediaDiscoveryEnabled
        )
    }
    
    private func isBackupsRoot(node: NodeEntity) -> Bool {
        backupsUseCase.isBackupsRootNode(node)
    }
    
    private func isBackupsChild(node: NodeEntity) -> Bool {
        if !isBackupsRoot(node: node) {
            return backupsUseCase.isBackupNode(node)
        } else {
            return false
        }
    }
    
    private func isRubbishRoot(node: NodeEntity) -> Bool {
        nodeUseCase.isRubbishBinRoot(node: node)
    }
}

extension NodeAccessTypeEntity {
    func toShareAccessLevelEntity() -> ShareAccessLevelEntity {
        switch self {
        case .unknown:
                .unknown
        case .read:
                .read
        case .readWrite:
                .readWrite
        case .full:
                .full
        case .owner:
                .owner
        }
    }
}
