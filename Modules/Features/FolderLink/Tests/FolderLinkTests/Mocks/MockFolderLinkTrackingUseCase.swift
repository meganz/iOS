import FolderLink
import MEGAUIComponent
import Search

final class MockFolderLinkTrackingUseCase: FolderLinkTrackingUseCaseProtocol, @unchecked Sendable {
    private(set) var trackSortHeaderPressedCalled = false
    private(set) var trackedViewMode: SearchResultsViewMode?
    private(set) var trackedSortOrder: MEGAUIComponent.SortOrder?
    
    func trackSortHeaderPressed() {
        trackSortHeaderPressedCalled = true
    }
    
    func trackViewModeChanged(_ viewMode: SearchResultsViewMode) {
        trackedViewMode = viewMode
    }
    
    func trackSortOrderChanged(_ sortOrder: MEGAUIComponent.SortOrder) {
        trackedSortOrder = sortOrder
    }
}
