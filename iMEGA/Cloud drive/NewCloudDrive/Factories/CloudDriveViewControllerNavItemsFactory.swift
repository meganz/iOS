import MEGADomain
import SwiftUI
import UIKit

struct CloudDriveViewControllerNavItemsFactory {
    let nodeSource: NodeSource
    let config: NodeBrowserConfig
    let currentViewMode: ViewModePreferenceEntity
    let contextMenuManager: ContextMenuManager
    let contextMenuConfigFactory: CloudDriveContextMenuConfigFactory
    let nodeUseCase: any NodeUseCaseProtocol
    let isSelectionHidden: Bool
    let sortOrder: SortOrderEntity

    /// Creates a SwiftUI context menu for a Node.
    ///
    /// This menu currently appears on the top trailing part navigation bar in the cloud drive.
    /// - Parameters:
    ///   - accessType: Access type for the node. Options are read, readwrite, full and owner.
    ///   - label: A view describing the content of the menu.
    /// - Returns: SwiftUI context menu.
    func contextMenu<Label: View>(@ViewBuilder label: @escaping () -> Label) -> ContextMenuWithButtonView<Label>? {
        guard let (parentNode, accessType) = parentNodeAndAccessType() else {
            return nil
        }

        let hasMedia = CloudDriveViewControllerMediaCheckerMode
            .containsSomeMedia
            .makeVisualMediaPresenceChecker(nodeSource: nodeSource, nodeUseCase: nodeUseCase)()

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
            isFromViewInFolder: config.isFromViewInFolder == true
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

    private func parentNodeAndAccessType() -> (NodeEntity, NodeAccessTypeEntity)? {
        guard case let .node(nodeProvider) = nodeSource, let parentNode = nodeProvider() else {
            return nil
        }

        let accessType = nodeUseCase.nodeAccessLevel(nodeHandle: parentNode.handle)
        return (parentNode, accessType)
    }
}
