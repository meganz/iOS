import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAUIComponent
import Search

protocol FolderLinkTrackingUseCaseProtocol: Sendable {
    func trackSortHeaderPressed()
    func trackViewModeChanged(_ viewMode: SearchResultsViewMode)
    func trackSortOrderChanged(_ sortOrder: MEGAUIComponent.SortOrder)
}

struct FolderLinkTrackingUseCase: FolderLinkTrackingUseCaseProtocol {
    private let tracker: any AnalyticsTracking
    
    package init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func trackSortHeaderPressed() {
        tracker.trackAnalyticsEvent(with: SortButtonPressedEvent())
    }
    
    func trackViewModeChanged(_ viewMode: Search.SearchResultsViewMode) {
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
    
    func trackSortOrderChanged(_ sortOrder: MEGAUIComponent.SortOrder) {
        let eventIdentifier: any EventIdentifier =  switch sortOrder.key {
        case .name:
            SortByNameMenuItemEvent()
        case .size:
            SortBySizeMenuItemEvent()
        case .linkCreated:
            SortByDateAddedMenuItemEvent()
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

