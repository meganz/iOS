@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
import MEGAUIComponent
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

    @Test(arguments: [
        (ViewModePreferenceEntity.list, SearchResultsViewMode.list),
        (ViewModePreferenceEntity.thumbnail, SearchResultsViewMode.grid)
    ])
    func testViewModeHeaderViewModel(inputViewMode: ViewModePreferenceEntity, expectedViewMode: SearchResultsViewMode) {
        let sut = makeSUT(viewMode: inputViewMode)
        #expect(sut.viewModeHeaderViewModel.selectedViewMode == expectedViewMode)
    }

    @Test func testListenToViewModeUpdates() async {
        enum TimeoutError: Error {
            case viewModeNotSet
        }

        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker, viewMode: .list)

        let result: Result<ViewModePreferenceEntity, any Error> = await withCheckedContinuation { continuation in
            var hasResumed = false

            func resume(_ result: Result<ViewModePreferenceEntity, any Error>) {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: result)
            }

            sut.invokeCommand = { command in
                switch command {
                case .setViewMode(let viewMode):
                    resume(.success(viewMode))
                default:
                    break
                }
            }

            sut.viewModeHeaderViewModel.selectedViewMode = .grid

            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                resume(.failure(TimeoutError.viewModeNotSet))
            }
        }

        switch result {
        case .success(let viewMode):
            #expect(viewMode == .thumbnail)
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [ViewModeGridMenuItemEvent()]
            )
        case .failure:
            Issue.record("Timed out waiting for .setViewMode(.thumbnail)")
        }
    }

    typealias SUT = FolderLinkViewModel
    func makeSUT(
        tracker: MockTracker = MockTracker(),
        sortOptions: [SortOption] = [.init(sortOrder: .init(key: .name), title: "", iconsByDirection: [:])],
        selectedSortOrder: MEGAUIComponent.SortOrder = .init(key: .name),
        viewMode: ViewModePreferenceEntity = .list
    ) -> SUT {
        .init(
            folderLinkUseCase: MockFolderLinkUseCase(),
            saveMediaUseCase: MockSaveMediaToPhotosUseCase(),
            sortHeaderCoordinator: .init(
                sortOptionsViewModel: .init(title: "", sortOptions: sortOptions),
                currentSortOrderProvider: { selectedSortOrder },
                sortOptionSelectionHandler: { _ in }
            ),
            viewMode: viewMode,
            tracker: tracker
        )
    }
}
