import FolderLink
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAUIComponent
import MEGATest
import Search
import Testing

@Suite("FolderLinkTrackingUseCase")
struct FolderLinkTrackingUseCaseTests {
    let tracker = MockTracker()
    
    @Test("Sends SortButtonPressedEvent")
    func trackSortHeaderPressed() {
        let sut = FolderLinkTrackingUseCase(tracker: tracker)

        sut.trackSortHeaderPressed()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SortButtonPressedEvent()]
        )
    }

    @Test(
        "Sends event when view mode changed",
        arguments: zip(
            [SearchResultsViewMode.list, .grid, .mediaDiscovery],
            [ViewModeListMenuItemEvent(), ViewModeGridMenuItemEvent(), ViewModeGalleryMenuItemEvent()]
        )
    )
    func trackViewModeChanged(viewMode: SearchResultsViewMode, event: any EventIdentifier) {
        let sut = FolderLinkTrackingUseCase(tracker: tracker)

        sut.trackViewModeChanged(viewMode)
        
        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [event])
    }

    // MARK: - trackSortOrderChanged
    @Test(
        "Send event when sort order changed",
        arguments: zip(
            [
                MEGAUIComponent.SortOrder(key: .name, direction: .ascending),
                SortOrder(key: .name, direction: .descending),
                SortOrder(key: .size, direction: .ascending),
                SortOrder(key: .size, direction: .descending),
                SortOrder(key: .linkCreated, direction: .ascending),
                SortOrder(key: .linkCreated, direction: .descending),
                SortOrder(key: .lastModified, direction: .ascending),
                SortOrder(key: .lastModified, direction: .descending),
                SortOrder(key: .label, direction: .ascending),
                SortOrder(key: .label, direction: .descending),
                SortOrder(key: .favourite, direction: .ascending),
                SortOrder(key: .favourite, direction: .descending),
                SortOrder(key: .shareCreated, direction: .ascending),
                SortOrder(key: .shareCreated, direction: .descending),
                SortOrder(key: .dateAdded, direction: .ascending),
                SortOrder(key: .dateAdded, direction: .descending),
            ],
            [
                SortByNameMenuItemEvent(),
                SortByNameMenuItemEvent(),
                SortBySizeMenuItemEvent(),
                SortBySizeMenuItemEvent(),
                SortByLinkCreationMenuItemEvent(),
                SortByLinkCreationMenuItemEvent(),
                SortByDateModifiedMenuItemEvent(),
                SortByDateModifiedMenuItemEvent(),
                SortByLabelMenuItemEvent(),
                SortByLabelMenuItemEvent(),
                SortByFavouriteMenuItemEvent(),
                SortByFavouriteMenuItemEvent(),
                SortByShareCreationMenuItemEvent(),
                SortByShareCreationMenuItemEvent(),
                SortByDateAddedMenuItemEvent(),
                SortByDateAddedMenuItemEvent()
            ]
        )
    )
    func trackSortOrderChanged(sortOrder: MEGAUIComponent.SortOrder, event: any EventIdentifier) {
        let sut = FolderLinkTrackingUseCase(tracker: tracker)

        sut.trackSortOrderChanged(sortOrder)
        
        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [event])
    }
}
