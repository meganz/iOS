import FolderLink
import MEGAUIComponent
import Search

final class MockFolderLinkTrackingUseCase: FolderLinkTrackingUseCaseProtocol, @unchecked Sendable {
    private(set) var trackSortHeaderPressedCalled = false
    private(set) var trackedViewMode: SearchResultsViewMode?
    private(set) var trackedSortOrder: MEGAUIComponent.SortOrder?
    private(set) var trackedBottomBarActions: [(action: FolderLinkBottomBarAction, source: FolderLinkActionSource)] = []
    private(set) var trackedQuickActions: [(action: FolderLinkQuickAction, source: FolderLinkActionSource)] = []

    func trackSortHeaderPressed() {
        trackSortHeaderPressedCalled = true
    }

    func trackBottomBarAction(_ action: FolderLinkBottomBarAction, from source: FolderLinkActionSource) {
        trackedBottomBarActions.append((action, source))
    }

    func trackQuickAction(_ action: FolderLinkQuickAction, from source: FolderLinkActionSource) {
        trackedQuickActions.append((action, source))
    }
    
    func trackViewModeChanged(_ viewMode: SearchResultsViewMode) {
        trackedViewMode = viewMode
    }
    
    func trackSortOrderChanged(_ sortOrder: MEGAUIComponent.SortOrder) {
        trackedSortOrder = sortOrder
    }
}
