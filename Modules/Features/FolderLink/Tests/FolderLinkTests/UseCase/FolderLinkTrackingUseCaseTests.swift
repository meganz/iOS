import FolderLink
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGATest
import MEGAUIComponent
import Search
import Testing

@Suite("FolderLinkTrackingUseCase")
struct FolderLinkTrackingUseCaseTests {
    let tracker = MockTracker()
    
    // MARK: - trackBottomBarAction

    @Test(
        "Sends the event the bottom bar action and its entry point map to",
        arguments: zip(
            [
                (FolderLinkBottomBarAction.addToCloudDrive, FolderLinkActionSource.anchoredButton),
                (.addToCloudDrive, .selectionToolbar),
                (.downloadToFiles, .anchoredButton),
                (.downloadToFiles, .selectionToolbar)
            ],
            [
                FolderLinkSaveToMegaAnchoredButtonPressedEvent(),
                FolderLinkSaveToMegaSelectionToolbarButtonPressedEvent(),
                FolderLinkDownloadAnchoredButtonPressedEvent(),
                FolderLinkDownloadSelectionToolbarButtonPressedEvent()
            ] as [any EventIdentifier]
        )
    )
    func trackBottomBarAction(
        input: (action: FolderLinkBottomBarAction, source: FolderLinkActionSource),
        event: any EventIdentifier
    ) {
        let sut = FolderLinkTrackingUseCase(tracker: tracker)

        sut.trackBottomBarAction(input.action, from: input.source)

        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [event])
    }

    /// Copy to Offline and Save to Photos sat on the pre-revamp bottom bar untracked, and this ticket only
    /// adds what the revamp introduced.
    @Test(
        "Sends nothing for the bottom bar actions that carry no event",
        arguments: [
            (FolderLinkBottomBarAction.makeAvailableOffline, FolderLinkActionSource.anchoredButton),
            (.makeAvailableOffline, .selectionToolbar),
            (.saveToPhotos, .selectionToolbar),
            (.addToCloudDrive, .moreOptionsMenu)
        ]
    )
    func trackBottomBarAction_untrackedCombination_sendsNothing(
        input: (action: FolderLinkBottomBarAction, source: FolderLinkActionSource)
    ) {
        let sut = FolderLinkTrackingUseCase(tracker: tracker)

        sut.trackBottomBarAction(input.action, from: input.source)

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    // MARK: - trackQuickAction

    @Test("Sends FolderLinkSaveToMegaMoreOptionsButtonPressedEvent for Save to MEGA in the sheet")
    func trackQuickAction_saveToMEGA() {
        let sut = FolderLinkTrackingUseCase(tracker: tracker)

        sut.trackQuickAction(.addToCloudDrive, from: .moreOptionsMenu)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [FolderLinkSaveToMegaMoreOptionsButtonPressedEvent()]
        )
    }

    /// Send to chat is reported by the app layer, Copy to Offline keeps its pre-revamp treatment of not
    /// being tracked, and Download has no more options event in mobile-analytics yet.
    @Test(
        "Sends nothing for the quick actions that carry no event",
        arguments: [FolderLinkQuickAction.makeAvailableOffline, .sendToChat, .downloadToFiles]
    )
    func trackQuickAction_untrackedAction_sendsNothing(action: FolderLinkQuickAction) {
        let sut = FolderLinkTrackingUseCase(tracker: tracker)

        sut.trackQuickAction(action, from: .moreOptionsMenu)

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

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
                SortOrder(key: .dateAdded, direction: .descending)
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
