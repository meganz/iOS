@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGATest
import XCTest

@MainActor
final class AudioPlaylistViewModelTests: XCTestCase {
    private let playerHandler = MockAudioPlayerHandler()
    private let defaultTimeout: TimeInterval = 0.05
    
    private var anyAudioNode: MockNode {
        MockNode(handle: 1, name: "first-audio.mp3", nodeType: .file)
    }
    
    private func makeSUT(router: (any AudioPlaylistViewRouting)? = nil) -> (AudioPlaylistViewModel, MockTracker) {
        let router = router ?? MockAudioPlaylistViewRouter()
        let tracker = MockTracker()
        let sut = AudioPlaylistViewModel(
            title: "",
            playerHandler: playerHandler,
            router: router,
            tracker: tracker
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000)
        return (sut, tracker)
    }
    
    func testDispatch_onViewDidLoadThroughDidDraggEnd_executesExpectedAudioPlayerCommands() async throws {
        let mockItem = AudioPlayerItem.mockItem
        playerHandler.mockPlayerCurrentItem = mockItem
        let (sut, _) = makeSUT()
        
        await test(
            viewModel: sut,
            action: .onViewDidLoad,
            expectedCommands: [
                .reloadTracks(currentItem: mockItem, queue: [], selectedIndexPaths: []),
                .title(title: "")
            ],
            timeout: defaultTimeout
        )
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        
        await test(viewModel: sut, action: .move(mockItem, IndexPath(row: 1, section: 0), .up), expectedCommands: [], timeout: defaultTimeout)
        XCTAssertEqual(playerHandler.onMoveItem_calledTimes, 1)
        
        await test(viewModel: sut, action: .didSelect(mockItem), expectedCommands: [.showToolbar], timeout: defaultTimeout)
        
        await test(viewModel: sut, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar], timeout: defaultTimeout)
        XCTAssertEqual(playerHandler.onDeleteItems_calledTimes, 1)
        
        await test(viewModel: sut, action: .didDeselect(mockItem), expectedCommands: [.hideToolbar], timeout: defaultTimeout)
        
        await test(viewModel: sut, action: .onViewWillDisappear, expectedCommands: [], timeout: defaultTimeout)
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        await test(viewModel: sut, action: .willDraggBegin, expectedCommands: [], timeout: defaultTimeout)
        
        let fileURL = try XCTUnwrap(Bundle.main.url(forResource: "audioClipSent", withExtension: "wav"))
        let track1 = AudioPlayerItem(name: "file 1", url: fileURL, node: nil)
        
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), reload: track1) },
            expectedCommands: [],
            timeout: defaultTimeout
        )
        
        await test(
            viewModel: sut,
            action: .didDraggEnd,
            expectedCommands: [.reload(items: [track1])],
            timeout: defaultTimeout
        )
    }
    
    func testDispatch_onDismiss_invokesRouterDismiss() async {
        let router = MockAudioPlaylistViewRouter()
        let (sut, _) = makeSUT(router: router)
        await test(viewModel: sut, action: .dismiss, expectedCommands: [], timeout: defaultTimeout)
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    func testDispatch_onRemoveSelectedItems_invokesRouterShowSnackBar_async() async {
        let router = MockAudioPlaylistViewRouter()
        let (sut, _) = makeSUT(router: router)
        
        await test(viewModel: sut, action: .didSelect(AudioPlayerItem.mockItem), expectedCommands: [.showToolbar], timeout: defaultTimeout)
        await test(viewModel: sut, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar], timeout: defaultTimeout)
        
        XCTAssertEqual(router.showSnackBar_calledTimes, 1)
    }
    
    func testDispatch_onMove_tracksReorderEvent() {
        let (sut, tracker) = makeSUT()
        let moved = AudioPlayerItem.mockItem
        sut.dispatch(.move(moved, IndexPath(row: 1, section: 0), .up))
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueReorderedEvent()]
        )
    }
    
    func testDispatch_onRemoveSelectedItems_tracksRemoveTracksEvent() {
        let (sut, tracker) = makeSUT()
        sut.dispatch(.removeSelectedItems)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueItemRemovedEvent()]
        )
    }
    
    func testAudioObserver_onQueueUpdate_reloadsTracksCommands() async {
        let mockItem = AudioPlayerItem.mockItem
        playerHandler.mockPlayerQueueItems = [mockItem]
        playerHandler.mockPlayerCurrentItem = mockItem
        let (sut, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: AVQueuePlayer(), currentItem: mockItem, queue: self.playerHandler.playerQueueItems())
            },
            expectedCommands: [
                .reloadTracks(currentItem: mockItem, queue: [mockItem], selectedIndexPaths: [])
            ]
        )
    }
    
    func testAudioObserver_reloadItemWithoutReordering_reloadsItems() async {
        let (sut, _) = makeSUT()
        let track = AudioPlayerItem(name: "Test", url: URL(string: "file://test.mp3")!, node: nil)
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: AVQueuePlayer(), reload: track)
            },
            expectedCommands: [.reload(items: [track])]
        )
    }
    
    func testAudioObserver_reloadItemDuringReordering_isDeferredUntilDidDraggEnd() async {
        let track = AudioPlayerItem(name: "Deferred", url: URL(string: "file://deferred.mp3")!, node: nil)
        let (sut, _) = makeSUT()
        
        await test(viewModel: sut, action: .willDraggBegin, expectedCommands: [], timeout: 0.1)
        
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), reload: track) },
            expectedCommands: [],
            timeout: 0.1
        )
        
        await test(
            viewModel: sut,
            action: .didDraggEnd,
            expectedCommands: [.reload(items: [track])],
            timeout: 0.1
        )
    }
    
    func testAudioObserver_onBlockingEvents_togglesUserInteractionCommands() async {
        let (sut, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: {
                sut.audioPlayerWillStartBlockingAction()
                sut.audioPlayerDidFinishBlockingAction()
            },
            expectedCommands: [.disableUserInteraction, .enableUserInteraction]
        )
    }
    
    func testDispatch_onDidSelectAndDidDeselect_togglesToolbarVisibility() {
        let item = AudioPlayerItem.mockItem
        
        test(
            viewModel: makeSUT().0,
            action: .didSelect(item),
            expectedCommands: [.showToolbar]
        )
        
        test(
            viewModel: makeSUT().0,
            action: .didDeselect(item),
            expectedCommands: [.hideToolbar]
        )
    }
    
    func testDispatch_onRemoveSelectedItems_clearsSelectionAndTracksEvent() async {
        let (sut, tracker) = makeSUT()
        
        await test(viewModel: sut, action: .didSelect(AudioPlayerItem.mockItem), expectedCommands: [.showToolbar], timeout: defaultTimeout)
        await test(viewModel: sut, action: .didSelect(AudioPlayerItem.mockItem), expectedCommands: [.showToolbar], timeout: defaultTimeout)
        await test(viewModel: sut, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar], timeout: defaultTimeout)
        
        XCTAssertEqual(playerHandler.onDeleteItems_calledTimes, 1)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueItemRemovedEvent()]
        )
    }
}
