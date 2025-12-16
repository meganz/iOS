import Combine
import MEGADomain
import SwiftUI

@MainActor
protocol MediaTabContentViewModel: AnyObject { }

// MARK: - Navigation Bar Item Provider

@MainActor
protocol MediaTabNavigationBarItemProvider {
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? { get }
        
    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel]
}

extension MediaTabNavigationBarItemProvider {
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? { nil }
}

// MARK: - Context Menu Provider

@MainActor
protocol MediaTabContextMenuProvider {
    func contextMenuConfiguration() -> CMConfigEntity?
}

// MARK: - Menu Action Handler
@MainActor
protocol MediaTabContextMenuActionHandler: AnyObject {
    /// Publisher that emits when edit mode should be toggled
    var editModeToggleRequested: PassthroughSubject<Void, Never> { get }

    func handleDisplayAction(_ action: DisplayActionEntity)
    func handleSortAction(_ sortType: SortOrderType)
    func handleQuickAction(_ action: QuickActionEntity)
    func handleVideoLocationFilter(_ filter: VideoLocationFilterEntity)
    func handleVideoDurationFilter(_ filter: VideoDurationFilterEntity)
}

// MARK: - Toolbar Actions Provider

@MainActor
protocol MediaTabToolbarActionsProvider: AnyObject {
    /// Publisher that emits when toolbar configuration should be updated
    /// Child view models should emit on this publisher whenever their selection state changes
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? { get }

    /// Provides the toolbar configuration to display
    /// The view model calculates this based on its own internal state
    func toolbarConfig() -> MediaBottomToolbarConfig?
}

extension MediaTabToolbarActionsProvider {
    /// Default implementation that returns nil
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? { nil }
}

// MARK: - Toolbar Action Handler

@MainActor
protocol MediaTabToolbarActionHandler: AnyObject {
    /// Coordinator that handles the UI operations for toolbar actions
    var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)? { get set }

    /// Handle toolbar action by delegating to the coordinator
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

    func handleVideoLocationFilter(_ filter: VideoLocationFilterEntity) {
        // Default: do nothing
    }

    func handleVideoDurationFilter(_ filter: VideoDurationFilterEntity) {
        // Default: do nothing
    }
}

// MARK: - Shared Resource Provider

/// Protocol for providing shared resources that are used across multiple tabs
@MainActor
protocol MediaTabSharedResourceProvider: AnyObject {
    var cameraUploadStatusButtonViewModel: CameraUploadStatusButtonViewModel { get }
    var contextMenuConfig: CMConfigEntity? { get }
    var contextMenuManager: ContextMenuManager? { get }
    var editMode: EditMode { get }
    var editModePublisher: Published<EditMode>.Publisher { get }
}

// MARK: - Shared Resource Consumer

@MainActor
protocol MediaTabSharedResourceConsumer: AnyObject {
    var sharedResourceProvider: (any MediaTabSharedResourceProvider)? { get set }
}

// MARK: - Navigation Title Updates

@MainActor
protocol MediaTabNavigationTitleProvider {
    var titleUpdatePublisher: AnyPublisher<String, Never> { get }
}
