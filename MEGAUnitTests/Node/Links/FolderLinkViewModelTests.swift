@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
import MEGATest
import Search
import Testing

@MainActor
@Suite("FolderLinkViewModel")
struct FolderLinkViewModelTests {

    @Test("Send to chat folder link")
    func testTrackSendToChatFolderLink() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.dispatch(.trackSendToChatFolderLink)

        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [SendToChatFolderLinkButtonPressedEvent()])
    }
    
    @Test("Send to chat folder link no account logged")
    func testTrackSendToChatFolderLinkNoAccountLogged() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.dispatch(.trackSendToChatFolderLinkNoAccountLogged)

        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [SendToChatFolderLinkNoAccountLoggedButtonPressedEvent()])
    }

    @Test func testHeaderViewModel_shouldMatchResults() {
        let sut = makeSUT(
            sortOptions: [
                .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
                .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: [:]),
                .init(sortOrder: .init(key: .favourite), title: "Favourite", iconsByDirection: [:]),
                .init(sortOrder: .init(key: .dateAdded), title: "Date added", iconsByDirection: [:])
            ],
            selectedSortOrder: .init(key: .name)
        )
        let headerViewModel = sut.sortHeaderViewModel
        #expect(headerViewModel.displaySortOptionsViewModel.sortOptions.map(\.sortOrder) == [
            .init(key: .name, direction: .descending),
            .init(key: .favourite),
            .init(key: .dateAdded)
        ])
    }

    typealias SUT = FolderLinkViewModel
    func makeSUT(
        tracker: MockTracker = MockTracker(),
        sortOptions: [SearchResultsSortOption] = [],
        selectedSortOrder: Search.SortOrderEntity = .init(key: .name)
    ) -> SUT {
        .init(
            folderLinkUseCase: MockFolderLinkUseCase(),
            saveMediaUseCase: MockSaveMediaToPhotosUseCase(),
            sortHeaderCoordinator: .init(
                sortOptionsViewModel: .init(title: "", sortOptions: sortOptions),
                currentSortOrderProvider: { selectedSortOrder },
                sortOptionSelectionHandler: { _ in }
            ),
            tracker: tracker
        )
    }
}
