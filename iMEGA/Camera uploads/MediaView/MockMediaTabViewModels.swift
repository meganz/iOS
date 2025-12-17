import Combine
import MEGADomain
import SwiftUI

// MARK: - Mock ViewModels for Debugging

final class MockVideoViewModel: MediaTabContextMenuProvider, MediaTabContextMenuActionHandler, MediaTabToolbarActionsProvider, MediaTabToolbarActionHandler, MediaTabNavigationBarItemProvider, MediaTabSharedResourceConsumer {
    private var selectedNodesForToolbar: [NodeEntity] = []

    var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?

    let editModeToggleRequested = PassthroughSubject<Void, Never>()

    // MARK: - Shared Resources

    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)?

    // MARK: - MediaTabContextMenuProvider

    func contextMenuConfiguration() -> CMConfigEntity? {
        return CMConfigEntity(
            menuType: .menu(type: .display),
            viewMode: .list,
            sortType: .modificationDesc,
            isSelectHidden: false,
            isEmptyState: false
        )
    }

    // MARK: - MediaTabToolbarActionsProvider

    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let nodes = selectedNodesForToolbar
        let count = nodes.count
        guard count > 0 else { return nil }

        let exportedNodes = nodes.filter { $0.isExported }
        let hasExportedItems = !exportedNodes.isEmpty
        let isAllExported = exportedNodes.count == count

        let actions: [MediaBottomToolbarAction] = isAllExported
            ? [.shareLink, .removeLink, .delete]
            : [.shareLink, .delete]

        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: count,
            hasExportedItems: hasExportedItems,
            isAllExported: isAllExported
        )
    }

    // MARK: - MediaTabToolbarActionHandler

    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        switch action {
        case .shareLink:
            print("MockVideoViewModel: Share link action")
        case .removeLink:
            print("MockVideoViewModel: Remove link action")
        case .delete:
            print("MockVideoViewModel: Delete action")
        default:
            print("MockVideoViewModel: Other action")
        }
    }

    // MARK: - Navigation Bar Item Provider

    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []
        
        let navItemId = "video"
        if editMode == .active {
            items.append(MediaNavigationBarItemFactory.selectAllButton(id: navItemId) {
                print("MockVideoViewModel: Select All tapped")
            })

            items.append(MediaNavigationBarItemFactory.cancelButton(id: navItemId) {
                print("MockVideoViewModel: Cancel tapped")
            })
        } else {
            items.append(MediaNavigationBarItemFactory.searchButton(id: navItemId) {
                print("MockVideoViewModel: Search tapped")
            })
        }

        return items
    }
}

final class MockPlaylistViewModel: MediaTabContentViewModel, MediaTabContextMenuProvider, MediaTabContextMenuActionHandler, MediaTabToolbarActionsProvider, MediaTabToolbarActionHandler, MediaTabNavigationBarItemProvider, MediaTabSharedResourceConsumer {
    private var selectedNodesForToolbar: [NodeEntity] = []

    var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?

    let editModeToggleRequested = PassthroughSubject<Void, Never>()

    // MARK: - Shared Resources

    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)?

    // MARK: - MediaTabContextMenuProvider

    func contextMenuConfiguration() -> CMConfigEntity? {
        return CMConfigEntity(
            menuType: .menu(type: .display),
            viewMode: .list,
            sortType: .modificationDesc,
            isSelectHidden: false,
            isEmptyState: false
        )
    }

    // MARK: - MediaTabToolbarActionsProvider

    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let nodes = selectedNodesForToolbar
        let count = nodes.count
        guard count > 0 else { return nil }

        let exportedNodes = nodes.filter { $0.isExported }
        let hasExportedItems = !exportedNodes.isEmpty
        let isAllExported = exportedNodes.count == count

        let actions: [MediaBottomToolbarAction] = isAllExported
            ? [.shareLink, .removeLink, .delete]
            : [.shareLink, .delete]

        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: count,
            hasExportedItems: hasExportedItems,
            isAllExported: isAllExported
        )
    }

    // MARK: - MediaTabToolbarActionHandler

    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        switch action {
        case .shareLink:
            print("MockPlaylistViewModel: Share link action")
        case .removeLink:
            print("MockPlaylistViewModel: Remove link action")
        case .delete:
            print("MockPlaylistViewModel: Delete action")
        default:
            print("MockVideoViewModel: Other action")
        }
    }

    // MARK: - Navigation Bar Item Provider

    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []
        
        let navItemId = "playlist"
        if editMode == .active {
            items.append(MediaNavigationBarItemFactory.selectAllButton(id: navItemId) {
                print("MockPlaylistViewModel: Select All tapped")
            })

            items.append(MediaNavigationBarItemFactory.cancelButton(id: navItemId) {
                print("MockPlaylistViewModel: Cancel tapped")
            })
        } else {
            items.append(MediaNavigationBarItemFactory.searchButton(id: navItemId) {
                print("MockPlaylistViewModel: Search tapped")
            })
        }

        return items
    }
}
