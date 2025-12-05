import Combine
import MEGADomain
import SwiftUI

// MARK: - Navigation Bar Item Provider

protocol MediaTabNavigationBarItemProvider {
    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel]
}

// MARK: - Context Menu Provider

protocol MediaTabContextMenuProvider {
    func contextMenuConfiguration() -> CMConfigEntity?
}

// MARK: - Menu Action Handler

protocol MediaTabContextMenuActionHandler: AnyObject {
    /// Publisher that emits when edit mode should be toggled
    var editModeToggleRequested: PassthroughSubject<Void, Never> { get }

    func handleDisplayAction(_ action: DisplayActionEntity)
    func handleSortAction(_ sortType: SortOrderType)
    func handleQuickAction(_ action: QuickActionEntity)
}

// MARK: - Toolbar Actions Provider

protocol MediaTabToolbarActionsProvider: AnyObject {
    func toolbarActions(
        selectedItemsCount: Int,
        hasExportedItems: Bool,
        isAllExported: Bool
    ) -> [MediaBottomToolbarAction]?
}

// MARK: - Toolbar Action Handler

protocol MediaTabToolbarActionHandler: AnyObject {
    /// Handle toolbar action for this tab
    /// - Parameter action: The toolbar action to handle
    func handleToolbarAction(_ action: MediaBottomToolbarAction)
}

// MARK: - Default Implementations

extension MediaTabContextMenuActionHandler {
    func handleDisplayAction(_ action: DisplayActionEntity) {
        if action == .select {
            editModeToggleRequested.send()
        }
    }

    func handleSortAction(_ sortType: SortOrderType) {
        // Default: do nothing
    }

    func handleQuickAction(_ action: QuickActionEntity) {
        // Default: do nothing
    }
}

// MARK: - Shared Resource Provider

/// Protocol for providing shared resources that are used across multiple tabs
protocol MediaTabSharedResourceProvider: AnyObject {
    var cameraUploadStatusButtonViewModel: CameraUploadStatusButtonViewModel { get }
    var contextMenuConfig: CMConfigEntity? { get }
    var contextMenuManager: ContextMenuManager? { get }
}

// MARK: - Shared Resource Consumer

protocol MediaTabSharedResourceConsumer: AnyObject {
    var sharedResourceProvider: (any MediaTabSharedResourceProvider)? { get set }
}
