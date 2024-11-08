import MEGADomain
import MEGADomainMock
@testable import Video
import XCTest

final class RecentlyWatchedVideosViewModelTests: XCTestCase {
    
    @MainActor
    func testInit_whenCalled_doesNotRequestUseCase() {
        let (_, recentlyWatchedVideosUseCase, _, _) = makeSUT()
        
        XCTAssertTrue(recentlyWatchedVideosUseCase.invocations.isEmpty)
    }
    
    @MainActor
    func testInit_whenCalled_inInitialState() {
        let (sut, _, _, _) = makeSUT()
        
        XCTAssertEqual(sut.viewState, .partial)
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenCalled_loadVideosThenSorted() async {
        let (sut, recentlyWatchedVideosUseCase, sorter, _) = makeSUT(
            recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase(loadNodesResult: .success([]))
        )
        
        await sut.loadRecentlyWatchedVideos()
        
        XCTAssertEqual(recentlyWatchedVideosUseCase.invocations, [ .loadNodes ])
        XCTAssertEqual(sorter.invocations, [ .sortVideosByDay ])
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenLoadedWithError_showsError() async {
        let (sut, _, _, _) = makeSUT()
        
        await sut.loadRecentlyWatchedVideos()
        
        XCTAssertEqual(sut.viewState, .error)
    }
    
    @MainActor
    func testLoadRecentlyWatchedVideos_whenLoadedWithError_showsCorrectTransitionViewState() async {
        let (sut, _, _, _) = makeSUT(
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
        let (sut, _, _, _) = makeSUT(
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
        let (sut, _, _, _) = makeSUT(
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
    
    // MARK: - didTapRubbishBinBarButtonItem
    
    @MainActor
    func testDidTapRubbishBinBarButtonItem_whenTapped_shouldShowDeleteAlert() {
        let (sut, _, _, sharedUIState) = makeSUT()
        let exp = expectation(description: "should toggle show delete alert")
        exp.expectedFulfillmentCount = 2
        var receivedValue: Bool?
        let cancellable = sut.$shouldShowDeleteAlert
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink {
                receivedValue = $0
                exp.fulfill()
            }
        
        sharedUIState.shouldShowDeleteAlert = true
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertEqual(receivedValue, true)
        cancellable.cancel()
    }
    
    // MARK: - isRubbishBinBarButtonItemEnabled
    
    @MainActor
    func testIsRubbishBinBarButtonItemEnabled_whenEmptyItems_disableButton() async {
        let (sut, _, _, sharedUIState) = makeSUT(
            recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase(loadNodesResult: .success([])),
            recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter(sortVideosByDayResult: [])
        )
        let exp = expectation(description: "should toggle rubbish bin button enabled")
        var isEnabled: Bool?
        let cancellable = sharedUIState.$isRubbishBinBarButtonItemEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink {
                isEnabled = $0
                exp.fulfill()
            }
        
        await sut.loadRecentlyWatchedVideos()
        await fulfillment(of: [exp], timeout: 0.1)
        
        XCTAssertEqual(isEnabled, false)
        cancellable.cancel()
    }
    
    @MainActor
    func testIsRubbishBinBarButtonItemEnabled_whenNonEmptyItems_enableButton() async {
        let itemCount = 3
        let items = nonEmptyItems(count: itemCount)
        let sections = [ RecentlyWatchedVideoSection(title: "any section title", videos: items) ]
        let (sut, _, _, sharedUIState) = makeSUT(
            recentlyWatchedVideosUseCase: MockRecentlyOpenedNodesUseCase(loadNodesResult: .success(items)),
            recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter(sortVideosByDayResult: sections)
        )
        let exp = expectation(description: "should toggle rubbish bin button enabled")
        var isEnabled: Bool?
        let cancellable = sharedUIState.$isRubbishBinBarButtonItemEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink {
                isEnabled = $0
                exp.fulfill()
            }
        
        await sut.loadRecentlyWatchedVideos()
        await fulfillment(of: [exp], timeout: 0.1)
        
        XCTAssertEqual(isEnabled, true)
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
        recentlyWatchedVideosSorter: MockRecentlyWatchedVideosSorter,
        sharedUIState: RecentlyWatchedVideosSharedUIState
    ) {
        let sharedUIState = RecentlyWatchedVideosSharedUIState()
        let sut = RecentlyWatchedVideosViewModel(
            recentlyOpenedNodesUseCase: recentlyWatchedVideosUseCase,
            recentlyWatchedVideosSorter: recentlyWatchedVideosSorter,
            sharedUIState: sharedUIState
        )
        return (sut, recentlyWatchedVideosUseCase, recentlyWatchedVideosSorter, sharedUIState)
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
