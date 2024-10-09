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
            recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase(loadNodesResult: .success([]))
        )
        
        await sut.loadRecentlyWatchedVideos()
        
        XCTAssertEqual(recentlyWatchedVideosUseCase.invocations, [ .loadNodes ])
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
            recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase(loadNodesResult: .failure(GenericErrorEntity()))
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
            recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase(loadNodesResult: .success([]))
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
            recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase(loadNodesResult: .success(items)),
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
        recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase = MockRecentlyOpenedNodesUseCase(),
        recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter = MockRecentlyWatchedVideosSorter()
    ) -> (
        sut: RecentlyWatchedVideosViewModel,
        recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase,
        recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter
    ) {
        let sut = RecentlyWatchedVideosViewModel(
            recentlyOpenedNodesUseCase: recentlyWatchedVideosUseCase,
            recentlyWatchedVideosSorter: recentlyWatchedVideosSorter
        )
        return (sut, recentlyWatchedVideosUseCase, recentlyWatchedVideosSorter)
    }
    
    private func nonEmptyItems(count: Int) -> [RecentlyOpenedNodeEntity] {
        var items = [RecentlyOpenedNodeEntity]()
        for index in 0..<count {
            items.append(RecentlyOpenedNodeEntity(
                node: anyVideo(handle: index),
                lastOpenedDate: Date(),
                mediaDestination: MediaDestinationEntity(fingerprint: "any-fingerprint", destination: 0, timescale: 0)
            ))
        }
        return items
    }
    
    private func anyVideo(handle: Int) -> NodeEntity {
        NodeEntity(name: "video-\(handle).mp4", handle: HandleEntity(handle))
    }
}
