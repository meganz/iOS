import Combine
import MEGADomain
import SwiftUI

// MARK: - Mock ViewModels for Debugging

@MainActor
final class MockTimelineViewModel: MediaTabContentViewModel, MediaTabContextMenuProvider, MediaTabContextMenuActionHandler, MediaTabToolbarActionsProvider, MediaTabToolbarActionHandler, MediaTabNavigationBarItemProvider, MediaTabSharedResourceConsumer {

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

    func toolbarActions(
        selectedItemsCount: Int,
        hasExportedItems: Bool,
        isAllExported: Bool
    ) -> [MediaBottomToolbarAction]? {
        return [.shareLink, .delete]
    }

    // MARK: - MediaTabToolbarActionHandler

    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        switch action {
        case .shareLink:
            print("MockTimelineViewModel: Share link action")
        case .removeLink:
            print("MockTimelineViewModel: Remove link action")
        case .delete:
            print("MockTimelineViewModel: Delete action")
        }
    }

    // MARK: - Navigation Bar Item Provider

    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []
        if editMode == .active {
            // Edit mode
            items.append(MediaNavigationBarItemFactory.selectAllButton {
                print("MockTimelineViewModel: Select All tapped")
            })

            items.append(MediaNavigationBarItemFactory.cancelButton {[weak self] in
                self?.editModeToggleRequested.send()
            })
        } else {
            if let provider = sharedResourceProvider {
                // Camera upload status button (shared resource)
                items.append(MediaNavigationBarItemFactory.cameraUploadStatusButton(
                    viewModel: provider.cameraUploadStatusButtonViewModel
                ))
            }

            items.append(MediaNavigationBarItemFactory.searchButton {
                print("MockTimelineViewModel: Search tapped")
            })

            // Context menu button - tab ViewModel provides data, ViewBuilder creates view
            if let provider = sharedResourceProvider,
               let config = provider.contextMenuConfig,
               let manager = provider.contextMenuManager {
                items.append(MediaNavigationBarItemFactory.contextMenuButton(
                    config: config,
                    manager: manager
                ))
            }
        }

        return items
    }
}

final class MockAlbumViewModel: MediaTabContextMenuProvider, MediaTabContextMenuActionHandler, MediaTabToolbarActionsProvider, MediaTabToolbarActionHandler, MediaTabNavigationBarItemProvider, MediaTabSharedResourceConsumer {

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

    func toolbarActions(
        selectedItemsCount: Int,
        hasExportedItems: Bool,
        isAllExported: Bool
    ) -> [MediaBottomToolbarAction]? {
        if isAllExported {
            return [.shareLink, .removeLink, .delete]
        } else {
            return [.shareLink, .delete]
        }
    }

    // MARK: - MediaTabToolbarActionHandler

    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        switch action {
        case .shareLink:
            print("MockAlbumViewModel: Share link action")
        case .removeLink:
            print("MockAlbumViewModel: Remove link action")
        case .delete:
            print("MockAlbumViewModel: Delete action")
        }
    }

    // MARK: - Navigation Bar Item Provider

    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []
        
        let navItemId = "album"
        if editMode == .active {
            items.append(MediaNavigationBarItemFactory.selectAllButton(id: navItemId) {
                print("MockAlbumViewModel: Select All tapped")
            })

            items.append(MediaNavigationBarItemFactory.cancelButton(id: navItemId) {
                print("MockAlbumViewModel: Cancel tapped")
            })
        } else {
            items.append(MediaNavigationBarItemFactory.searchButton(id: navItemId) {
                print("MockAlbumViewModel: Search tapped")
            })
        }

        return items
    }
}

final class MockVideoViewModel: MediaTabContextMenuProvider, MediaTabContextMenuActionHandler, MediaTabToolbarActionsProvider, MediaTabToolbarActionHandler, MediaTabNavigationBarItemProvider, MediaTabSharedResourceConsumer {

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

    func toolbarActions(
        selectedItemsCount: Int,
        hasExportedItems: Bool,
        isAllExported: Bool
    ) -> [MediaBottomToolbarAction]? {
        if isAllExported {
            return [.shareLink, .removeLink, .delete]
        } else {
            return [.shareLink, .delete]
        }
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

    func toolbarActions(
        selectedItemsCount: Int,
        hasExportedItems: Bool,
        isAllExported: Bool
    ) -> [MediaBottomToolbarAction]? {
        if isAllExported {
            return [.shareLink, .removeLink, .delete]
        } else {
            return [.shareLink, .delete]
        }
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
