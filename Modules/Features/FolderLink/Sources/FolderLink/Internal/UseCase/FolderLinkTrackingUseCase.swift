import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAUIComponent
import Search

protocol FolderLinkTrackingUseCaseProtocol: Sendable {
    func trackSortHeaderPressed()
    func trackViewModeChanged(_ viewMode: SearchResultsViewMode)
    func trackSortOrderChanged(_ sortOrder: MEGAUIComponent.SortOrder)
}

package struct FolderLinkTrackingUseCase: FolderLinkTrackingUseCaseProtocol {
    private let tracker: any AnalyticsTracking
    
    package init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    package func trackSortHeaderPressed() {
        tracker.trackAnalyticsEvent(with: SortButtonPressedEvent())
    }
    
    package func trackViewModeChanged(_ viewMode: Search.SearchResultsViewMode) {
        let eventIdentifier: any EventIdentifier =  switch viewMode {
        case .list:
            ViewModeListMenuItemEvent()
        case .grid:
            ViewModeGridMenuItemEvent()
        case .mediaDiscovery:
            ViewModeGalleryMenuItemEvent()
        }
        tracker.trackAnalyticsEvent(with: eventIdentifier)
    }
    
    package func trackSortOrderChanged(_ sortOrder: MEGAUIComponent.SortOrder) {
        let eventIdentifier: any EventIdentifier =  switch sortOrder.key {
        case .name:
            SortByNameMenuItemEvent()
        case .size:
            SortBySizeMenuItemEvent()
        case .linkCreated:
            SortByLinkCreationMenuItemEvent()
        case .lastModified:
            SortByDateModifiedMenuItemEvent()
        case .label:
            SortByLabelMenuItemEvent()
        case .favourite:
            SortByFavouriteMenuItemEvent()
        case .shareCreated:
            SortByShareCreationMenuItemEvent()
        case .dateAdded:
            SortByDateAddedMenuItemEvent()
        }
        tracker.trackAnalyticsEvent(with: eventIdentifier)
    }
}

