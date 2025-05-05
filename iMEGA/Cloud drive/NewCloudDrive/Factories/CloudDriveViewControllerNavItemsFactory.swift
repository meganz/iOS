import MEGADomain
import SwiftUI
import UIKit

/// Factory struct to construct the navigation items of CloudDrive
/// This factory will construct the navigation items needed for the CD page based on the latest state of the parent node.
struct CloudDriveViewControllerNavItemsFactory {
    let nodeSource: NodeSource
    let config: NodeBrowserConfig
    let currentViewMode: ViewModePreferenceEntity
    let contextMenuManager: ContextMenuManager
    let contextMenuConfigFactory: CloudDriveContextMenuConfigFactory
    let nodeUseCase: any NodeUseCaseProtocol
    let isSelectionHidden: Bool
    let sortOrder: SortOrderEntity
    let isHidden: Bool?

    /// Creates a SwiftUI context menu for a Node.
    ///
    /// This menu currently appears on the top trailing part navigation bar in the cloud drive.
    /// - Parameters:
    ///   - accessType: Access type for the node. Options are read, readwrite, full and owner.
    ///   - label: A view describing the content of the menu.
    /// - Returns: SwiftUI context menu.
    func contextMenu<Label: View>(@ViewBuilder label: @escaping () -> Label) -> ContextMenuWithButtonView<Label>? {
        // First, get the most updated value of parentNode and access type
        guard let (parentNode, accessType) = parentNodeAndAccessType() else {
            return nil
        }

        let hasMedia = CloudDriveViewControllerMediaCheckerMode
            .containsSomeMedia
            .makeVisualMediaPresenceChecker(nodeSource: nodeSource, nodeUseCase: nodeUseCase)()
        
        let isTakenDownFolderNode: () -> Bool = {
            guard
                case let .node(nodeProvider) = nodeSource,
                let node = nodeProvider()
            else { return false }
            return node.isFolder && node.isTakenDown
        }

        let menuConfig = contextMenuConfigFactory.contextMenuConfiguration(
            parentNode: parentNode,
            nodeAccessType: accessType,
            currentViewMode: currentViewMode,
            isSelectionHidden: isSelectionHidden,
            showMediaDiscovery: sharedShouldShowMediaDiscoveryContextMenuOption(
                mediaDiscoveryDetectionEnabled: !nodeSource.isRoot,
                hasMediaFiles: hasMedia,
                isFromSharedItem: config.isFromSharedItem == true,
                viewModePreference: currentViewMode
            ),
            sortOrder: sortOrder,
            displayMode: config.displayMode?.carriedOverDisplayMode ?? .cloudDrive,
            isFromViewInFolder: config.isFromViewInFolder == true,
            isHidden: isHidden,
            isTakenDownFolder: isTakenDownFolderNode()
        )

        guard let menuConfig else { return nil }

        return contextMenuManager.menu(with: menuConfig, label: label)
    }
    
    /// Creates a SwiftUI menu with options that can be used to add a new node to a particular node.
    ///
    /// This menu currently appears on the top trailing part navigation bar in the cloud drive (button with + image).
    /// - Parameter label: A view describing the content of the menu.
    /// - Returns: SwiftUI menu displaying options on tap to add a new node.
    func addMenu<Label: View>(@ViewBuilder label: @escaping () -> Label) -> ContextMenuWithButtonView<Label>? {
        guard config.isFromViewInFolder != true,
              config.displayMode != .rubbishBin,
              config.displayMode != .backup,
              let (_, accessType) = parentNodeAndAccessType(),
              accessType != .unknown,
              accessType != .read else {
            return nil
        }

        let addBarMenuConfig = CMConfigEntity(menuType: .menu(type: .uploadAdd), viewMode: currentViewMode)
        return contextMenuManager.menu(with: addBarMenuConfig, label: label)
    }
    
    // MARK: - Private

    /// Get the most updated value of parentNode and access type.
    /// Because a CD node can be changed externally (e.g: User rename or change access type of the node from another platform/device),
    /// in order to construct the navigation items correctly we need to get the most updated value of the node and its access type.
    private func parentNodeAndAccessType() -> (NodeEntity, NodeAccessTypeEntity)? {
        guard case let .node(nodeProvider) = nodeSource,
                let handle = nodeProvider()?.handle,
              let parentNode = nodeUseCase.nodeForHandle(handle)
        else {
            return nil
        }
        
        let accessType = nodeUseCase.nodeAccessLevel(nodeHandle: parentNode.handle)
        return (parentNode, accessType)
    }
    
    private func sharedShouldShowMediaDiscoveryContextMenuOption(
        mediaDiscoveryDetectionEnabled: Bool, // can't inject node here as we need to handle nil case (happens during offline starts)
        hasMediaFiles: Bool?,
        isFromSharedItem: Bool,
        viewModePreference: ViewModePreferenceEntity
    ) -> Bool {
        let shouldAutomaticallyShowMediaView = mediaDiscoveryDetectionEnabled &&
        hasMediaFiles == true && !isFromSharedItem
        return shouldAutomaticallyShowMediaView || viewModePreference == .mediaDiscovery
    }
}
