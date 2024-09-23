import MEGADomain
import MEGADomainMock
@testable import Video
import XCTest

final class RecentlyWatchedVideosViewModelTests: XCTestCase {
    
    @MainActor
    func testInit_whenCalled_doesNotRequestUseCase() {
        let (_, recentlyWatchedVideosUseCase, _) = makeSUT()
        
        XCTAssertTrue(recentlyWatchedVideosUseCase.invocations.isEmpty)
    }
    
    @MainActor
    func testInit_whenCalled_inInitialState() {
        let (sut, _, _) = makeSUT()
        
        XCTAssertEqual(sut.viewState, .partial)
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenCalled_loadVideosThenSorted() async {
        let (sut, recentlyWatchedVideosUseCase, sorter) = makeSUT(
            recentlyWatchedVideosUseCase: MockRecentlyWatchedVideosUseCase(loadVideosResult: .success([]))
        )
        
        await sut.loadRecentlyWatchedVideos()
        
        XCTAssertEqual(recentlyWatchedVideosUseCase.invocations, [ .loadVideos ])
        XCTAssertEqual(sorter.invocations, [ .sortVideosByDay ])
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenLoadedWithError_showsError() async {
        let (sut, _, _) = makeSUT()
        
        await sut.loadRecentlyWatchedVideos()
        
        XCTAssertEqual(sut.viewState, .error)
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenLoadedWithError_showsCorrectTransitionViewState() async {
        let (sut, _, _) = makeSUT(
            recentlyWatchedVideosUseCase: MockRecentlyWatchedVideosUseCase(loadVideosResult: .failure(GenericErrorEntity()))
        )
        var receivedViewStates: [RecentlyWatchedVideosViewModel.ViewState] = []
        let exp = expectation(description: "subscribe on viewState")
        exp.expectedFulfillmentCount = 3
        let cancellable = sut.$viewState
            .sink { viewState in
                receivedViewStates.append(viewState)
                exp.fulfill()
            }
        
        await sut.loadRecentlyWatchedVideos()
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedViewStates, [ .partial, .loading, .error ])
        XCTAssertTrue(sut.recentlyWatchedSections.isEmpty)
        cancellable.cancel()
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenLoadedSuccessfullyWithEmptyItems_showsCorrectTransitionViewState() async {
        let (sut, _, _) = makeSUT(
            recentlyWatchedVideosUseCase: MockRecentlyWatchedVideosUseCase(loadVideosResult: .success([]))
        )
        var receivedViewStates: [RecentlyWatchedVideosViewModel.ViewState] = []
        let exp = expectation(description: "subscribe on viewState")
        exp.expectedFulfillmentCount = 3
        let cancellable = sut.$viewState
            .sink { viewState in
                receivedViewStates.append(viewState)
                exp.fulfill()
            }
        
        await sut.loadRecentlyWatchedVideos()
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedViewStates, [ .partial, .loading, .empty ])
        XCTAssertTrue(sut.recentlyWatchedSections.isEmpty)
        cancellable.cancel()
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenNonEmptyItemsLoadedSuccessfully_showsCorrectTransitionViewState() async {
        let itemCount = 3
        let items = nonEmptyItems(count: itemCount)
        let sections = [ RecentlyWatchedVideoSection(title: "any section title", videos: items) ]
        let (sut, _, _) = makeSUT(
            recentlyWatchedVideosUseCase: MockRecentlyWatchedVideosUseCase(loadVideosResult: .success(items)),
            recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter(sortVideosByDayResult: sections)
        )
        var receivedViewStates: [RecentlyWatchedVideosViewModel.ViewState] = []
        let exp = expectation(description: "subscribe on viewState")
        exp.expectedFulfillmentCount = 3
        let cancellable = sut.$viewState
            .sink { viewState in
                receivedViewStates.append(viewState)
                exp.fulfill()
            }
        
        await sut.loadRecentlyWatchedVideos()
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedViewStates, [ .partial, .loading, .loaded ])
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(
        recentlyWatchedVideosUseCase: MockRecentlyWatchedVideosUseCase = MockRecentlyWatchedVideosUseCase(),
        recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter = MockRecentlyWatchedVideosSorter()
    ) -> (
        sut: RecentlyWatchedVideosViewModel,
        recentlyWatchedVideosUseCase: MockRecentlyWatchedVideosUseCase,
        recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter
    ) {
        let sut = RecentlyWatchedVideosViewModel(
            recentlyWatchedVideosUseCase: recentlyWatchedVideosUseCase,
            recentlyWatchedVideosSorter: recentlyWatchedVideosSorter
        )
        return (sut, recentlyWatchedVideosUseCase, recentlyWatchedVideosSorter)
    }
    
    private func nonEmptyItems(count: Int) -> [RecentlyWatchedVideoEntity] {
        var items = [RecentlyWatchedVideoEntity]()
        for index in 0..<count {
            items.append(RecentlyWatchedVideoEntity(video: anyVideo(handle: index), lastWatchedDate: Date(), mediaDestination: nil))
        }
        return items
    }
    
    private func anyVideo(handle: Int) -> NodeEntity {
        NodeEntity(name: "video-\(handle).mp4", handle: HandleEntity(handle))
    }
}
