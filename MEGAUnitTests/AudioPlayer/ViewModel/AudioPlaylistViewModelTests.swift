@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGATest
import XCTest

@MainActor
final class AudioPlaylistViewModelTests: XCTestCase {
    private let defaultTimeout: TimeInterval = 0.1
    private let defaultTitle = ""
    private let sampleWavResourceName = "audioClipSent"
    private let sampleWavExtension = "wav"
    
    private func makePlayerHandler(
        currentItem: AudioPlayerItem,
        queueItems: [AudioPlayerItem]? = nil
    ) -> MockAudioPlayerHandler {
        let playerHandler = MockAudioPlayerHandler()
        playerHandler.mockPlayerCurrentItem = currentItem
        playerHandler.mockPlayerQueueItems = queueItems
        return playerHandler
    }
    
    private func makeSUT(
        router: (any AudioPlaylistViewRouting)? = nil,
        handler: MockAudioPlayerHandler,
        title: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlaylistViewModel, tracker: MockTracker, playerHandler: MockAudioPlayerHandler) {
        let resolvedRouter = router ?? MockAudioPlaylistViewRouter()
        let tracker = MockTracker()
        let sut = AudioPlaylistViewModel(
            title: title ?? defaultTitle,
            playerHandler: handler,
            router: resolvedRouter,
            tracker: tracker
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, tracker, handler)
    }
    
    private func bundledAudioURL(
        resource name: String? = nil,
        ext: String? = nil
    ) throws -> URL {
        try XCTUnwrap(Bundle.main.url(
            forResource: name ?? sampleWavResourceName,
            withExtension: ext ?? sampleWavExtension
        ))
    }
    
    func testOnViewDidLoad_emitsTitleAndInitialReload_andAddsListenerOnce() async {
        let currentItem = AudioPlayerItem.mockItem
        let handler = makePlayerHandler(currentItem: currentItem)
        let (sut, _, playerHandler) = makeSUT(handler: handler)
        
        await test(
            viewModel: sut,
            action: .onViewDidLoad,
            expectedCommands: [
                .reloadTracks(currentItem: currentItem, queue: [], selectedIndexPaths: []),
                .title(title: "")
            ],
            timeout: defaultTimeout
        )
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
    }
    
    func testMove_invokesHandlerOnce() async {
        let itemToMove = AudioPlayerItem.mockItem
        let (sut, _, playerHandler) = makeSUT(handler: makePlayerHandler(currentItem: itemToMove))
        
        await test(
            viewModel: sut,
            action: .move(itemToMove, IndexPath(row: 1, section: 0), .up),
            expectedCommands: [],
            timeout: defaultTimeout
        )
        XCTAssertEqual(playerHandler.onMoveItem_calledTimes, 1)
    }
    
    func testDidSelect_showsToolbar() async {
        let selectedItem = AudioPlayerItem.mockItem
        let (sut, _, _) = makeSUT(handler: MockAudioPlayerHandler())
        
        await test(
            viewModel: sut,
            action: .didSelect(selectedItem),
            expectedCommands: [.showToolbar],
            timeout: defaultTimeout
        )
    }
    
    func testRemoveSelectedItems_deselectsAndHidesToolbar_andCallsDeleteOnce() async {
        let (sut, _, playerHandler) = makeSUT(handler: MockAudioPlayerHandler())
        
        await test(viewModel: sut, action: .didSelect(AudioPlayerItem.mockItem), expectedCommands: [.showToolbar], timeout: defaultTimeout)
        await test(viewModel: sut, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar], timeout: defaultTimeout)
        
        XCTAssertEqual(playerHandler.onDeleteItems_calledTimes, 1)
    }
    
    func testDidDeselect_hidesToolbar() async {
        let deselectedItem = AudioPlayerItem.mockItem
        let (sut, _, _) = makeSUT(handler: MockAudioPlayerHandler())
        
        await test(
            viewModel: sut,
            action: .didDeselect(deselectedItem),
            expectedCommands: [.hideToolbar],
            timeout: defaultTimeout
        )
    }
    
    func testOnViewWillDisappear_removesListenerOnce() async {
        let (sut, _, playerHandler) = makeSUT(handler: MockAudioPlayerHandler())
        
        await test(
            viewModel: sut,
            action: .onViewWillDisappear,
            expectedCommands: [],
            timeout: defaultTimeout
        )
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
    }
    
    func testDragReload_isDeferredUntilDidDragEnd() async throws {
        let (sut, _, _) = makeSUT(handler: MockAudioPlayerHandler())
        let track = AudioPlayerItem(name: "file 1", url: try bundledAudioURL(), node: nil)
        
        await test(viewModel: sut, action: .willDraggBegin, expectedCommands: [], timeout: defaultTimeout)
        
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), reload: track) },
            expectedCommands: [],
            timeout: defaultTimeout
        )
        
        await test(
            viewModel: sut,
            action: .didDraggEnd,
            expectedCommands: [.reload(items: [track])],
            timeout: defaultTimeout
        )
    }
    
    func testDismiss_invokesRouterDismiss() async {
        let router = MockAudioPlaylistViewRouter()
        let (sut, _, _) = makeSUT(router: router, handler: MockAudioPlayerHandler())
        
        await test(viewModel: sut, action: .dismiss, expectedCommands: [], timeout: defaultTimeout)
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    func testRemoveSelectedItems_showsSnackBar() async {
        let router = MockAudioPlaylistViewRouter()
        let (sut, _, _) = makeSUT(router: router, handler: MockAudioPlayerHandler())
        
        await test(viewModel: sut, action: .didSelect(AudioPlayerItem.mockItem), expectedCommands: [.showToolbar], timeout: defaultTimeout)
        await test(viewModel: sut, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar], timeout: defaultTimeout)
        
        XCTAssertEqual(router.showSnackBar_calledTimes, 1)
    }
    
    func testMove_tracksQueueReorderedEvent() {
        let (sut, tracker, _) = makeSUT(handler: MockAudioPlayerHandler())
        let movedItem = AudioPlayerItem.mockItem
        
        sut.dispatch(.move(movedItem, IndexPath(row: 1, section: 0), .up))
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueReorderedEvent()]
        )
    }
    
    func testRemoveSelectedItems_tracksQueueItemRemovedEvent() {
        let (sut, tracker, _) = makeSUT(handler: MockAudioPlayerHandler())
        
        sut.dispatch(.removeSelectedItems)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueItemRemovedEvent()]
        )
    }
    
    func testOnQueueUpdate_reloadsTracks() async {
        let current = AudioPlayerItem.mockItem
        let handler = makePlayerHandler(currentItem: current, queueItems: [current])
        let (sut, _, playerHandler) = makeSUT(handler: handler)
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(
                    player: AVQueuePlayer(),
                    currentItem: current,
                    queue: playerHandler.playerQueueItems()
                )
            },
            expectedCommands: [
                .reloadTracks(currentItem: current, queue: [current], selectedIndexPaths: [])
            ],
            timeout: defaultTimeout
        )
    }
    
    func testReloadItemWithoutReordering_emitsReloadItems() async {
        let (sut, _, _) = makeSUT(handler: MockAudioPlayerHandler())
        let track = AudioPlayerItem(name: "Test", url: URL(string: "file://test.mp3")!, node: nil)
        
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), reload: track) },
            expectedCommands: [.reload(items: [track])],
            timeout: defaultTimeout
        )
    }
    
    func testReloadItemDuringReordering_isDeferredUntilDidDragEnd() async {
        let deferredTrack = AudioPlayerItem(name: "Deferred", url: URL(string: "file://deferred.mp3")!, node: nil)
        let (sut, _, _) = makeSUT(handler: MockAudioPlayerHandler())
        
        await test(viewModel: sut, action: .willDraggBegin, expectedCommands: [], timeout: defaultTimeout)
        
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), reload: deferredTrack) },
            expectedCommands: [],
            timeout: defaultTimeout
        )
        
        await test(
            viewModel: sut,
            action: .didDraggEnd,
            expectedCommands: [.reload(items: [deferredTrack])],
            timeout: defaultTimeout
        )
    }
    
    func testBlockingEvents_toggleUserInteractionCommands() async {
        let (sut, _, _) = makeSUT(handler: MockAudioPlayerHandler())
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audioPlayerWillStartBlockingAction()
                sut.audioPlayerDidFinishBlockingAction()
            },
            expectedCommands: [.disableUserInteraction, .enableUserInteraction],
            timeout: defaultTimeout
        )
    }
}
