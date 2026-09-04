import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAUIComponent
import Search

/// Where an action was picked from. The revamp offers the folder's two main actions in three places, and
/// the events are split by entry point so the anchored buttons can be measured against the others.
package enum FolderLinkActionSource: Sendable {
    /// One of the two buttons anchored above the bottom safe area while browsing.
    case anchoredButton
    /// A row of the more options sheet behind the navigation bar more button.
    case moreOptionsMenu
    /// One of the bottom toolbar buttons a selection brings up.
    case selectionToolbar
}

package protocol FolderLinkTrackingUseCaseProtocol: Sendable {
    func trackSortHeaderPressed()
    func trackViewModeChanged(_ viewMode: SearchResultsViewMode)
    func trackSortOrderChanged(_ sortOrder: MEGAUIComponent.SortOrder)
    func trackBottomBarAction(_ action: FolderLinkBottomBarAction, from source: FolderLinkActionSource)
    func trackQuickAction(_ action: FolderLinkQuickAction, from source: FolderLinkActionSource)
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

    /// Copy to Offline and Save to Photos are not here: both sat on the pre-revamp bottom bar untracked,
    /// and this ticket only adds what the revamp introduced.
    package func trackBottomBarAction(_ action: FolderLinkBottomBarAction, from source: FolderLinkActionSource) {
        let eventIdentifier: (any EventIdentifier)? = switch (action, source) {
        case (.addToCloudDrive, .anchoredButton):
            FolderLinkSaveToMegaAnchoredButtonPressedEvent()
        case (.addToCloudDrive, .selectionToolbar):
            FolderLinkSaveToMegaSelectionToolbarButtonPressedEvent()
        case (.downloadToFiles, .anchoredButton):
            FolderLinkDownloadAnchoredButtonPressedEvent()
        case (.downloadToFiles, .selectionToolbar):
            FolderLinkDownloadSelectionToolbarButtonPressedEvent()
        default:
            nil
        }
        guard let eventIdentifier else { return }
        tracker.trackAnalyticsEvent(with: eventIdentifier)
    }

    /// Send to chat is not here: the app layer's action handler reports it through the events it already
    /// had. Copy to Offline keeps its pre-revamp treatment of not being tracked at all.
    package func trackQuickAction(_ action: FolderLinkQuickAction, from source: FolderLinkActionSource) {
        guard case .addToCloudDrive = action, case .moreOptionsMenu = source else { return }
        tracker.trackAnalyticsEvent(with: FolderLinkSaveToMegaMoreOptionsButtonPressedEvent())
    }
}
