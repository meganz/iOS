@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGATest
import XCTest

final class AudioPlaylistViewModelTests: XCTestCase {
    private let playerHandler = MockAudioPlayerHandler()
    private let tracker = MockTracker()
    private var anyAudioNode: MockNode {
        MockNode(handle: 1, name: "first-audio.mp3", nodeType: .file)
    }
    
    @MainActor
    private func makeSUT(
        router: (any AudioPlaylistViewRouting)? = nil,
        tracker: (any AnalyticsTracking)? = nil
    ) -> AudioPlaylistViewModel {
        let router = router ?? MockAudioPlaylistViewRouter()
        let tracker = tracker ?? MockTracker()
        let sut = AudioPlaylistViewModel(
            title: "",
            playerHandler: playerHandler,
            router: router,
            tracker: tracker
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000)
        return sut
    }
    
    @MainActor
    private func captureViewModelCommands(
        _ action: (AudioPlaylistViewModel, inout [AudioPlaylistViewModel.Command]) -> Void
    ) {
        let sut = makeSUT()
        var cmds: [AudioPlaylistViewModel.Command] = []
        sut.invokeCommand = { cmds.append($0) }
        action(sut, &cmds)
    }
    
    @MainActor
    func testDispatch_onViewDidLoadThroughDidDraggEnd_executesExpectedAudioPlayerCommands() throws {
        let mockItem = AudioPlayerItem.mockItem
        playerHandler.mockPlayerCurrentItem = mockItem
        let sut = makeSUT(tracker: tracker)
        
        test(viewModel: sut, action: .onViewDidLoad, expectedCommands: [
            .reloadTracks(currentItem: mockItem, queue: nil, selectedIndexPaths: []),
            .title(title: "")
        ])
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        
        test(viewModel: sut, action: .move(mockItem, IndexPath(row: 1, section: 0), .up), expectedCommands: [])
        XCTAssertEqual(playerHandler.onMoveItem_calledTimes, 1)
        
        test(viewModel: sut, action: .didSelect(mockItem), expectedCommands: [.showToolbar])
        
        test(viewModel: sut, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar])
        XCTAssertEqual(playerHandler.onDeleteItems_calledTimes, 1)
        
        test(viewModel: sut, action: .didDeselect(mockItem), expectedCommands: [.hideToolbar])
        
        test(viewModel: sut, action: .onViewWillDisappear, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        test(viewModel: sut, action: .willDraggBegin, expectedCommands: [])
        let fileURL = try XCTUnwrap(Bundle.main.url(forResource: "incoming_voice_video_call_iOS9", withExtension: "mp3"))
        let track1 = AudioPlayerItem(name: "file 1", url: fileURL, node: nil)
        sut.audio(player: AVQueuePlayer(), reload: track1)
        test(viewModel: sut, action: .didDraggEnd, expectedCommands: [.reload(items: [track1])])
    }
    
    @MainActor
    func testDispatch_onDismiss_invokesRouterDismiss() {
        let router = MockAudioPlaylistViewRouter()
        let sut = makeSUT(router: router)
        test(viewModel: sut, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    @MainActor
    func testDispatch_onMove_tracksReorderEvent() {
        let sut = makeSUT(tracker: tracker)
        let moved = AudioPlayerItem.mockItem
        sut.dispatch(.move(moved, IndexPath(row: 1, section: 0), .up))
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueReorderedEvent()]
        )
    }
    
    @MainActor
    func testDispatch_onRemoveSelectedItems_tracksRemoveTracksEvent() {
        let sut = makeSUT(tracker: tracker)
        sut.dispatch(.removeSelectedItems)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueItemRemovedEvent()]
        )
    }
    
    @MainActor
    func testAudioObserver_onQueueUpdate_reloadsTracksCommands() {
        let mockItem = AudioPlayerItem.mockItem
        playerHandler.mockPlayerQueueItems = [mockItem]
        playerHandler.mockPlayerCurrentItem = mockItem
        let sut = makeSUT()
        var cmds: [AudioPlaylistViewModel.Command] = []
        sut.invokeCommand = { cmds.append($0) }
        
        sut.audio(player: AVQueuePlayer(), currentItem: nil, queue: playerHandler.playerQueueItems())
        
        XCTAssertEqual(
            cmds,
            [.reloadTracks(
                currentItem: mockItem,
                queue: [mockItem],
                selectedIndexPaths: []
            )]
        )
    }
    
    @MainActor
    func testAudioObserver_reloadItemWithoutReordering_reloadsItems() {
        let sut = makeSUT()
        var cmds: [AudioPlaylistViewModel.Command] = []
        sut.invokeCommand = { cmds.append($0) }
        
        let track = AudioPlayerItem(name: "Test", url: URL(string: "file://test.mp3")!, node: nil)
        sut.audio(player: AVQueuePlayer(), reload: track)
        
        XCTAssertEqual(cmds, [.reload(items: [track])])
    }
    
    @MainActor
    func testAudioObserver_reloadItemDuringReordering_isDeferredUntilDidDraggEnd() {
        let track = AudioPlayerItem(
            name: "Deferred",
            url: URL(string: "file://deferred.mp3")!,
            node: nil
        )
        let expect = expectation(description: "Deferred reload should be delivered on didDraggEnd")
        
        let sut = makeSUT()
        var cmds: [AudioPlaylistViewModel.Command] = []
        sut.invokeCommand = { cmd in
            cmds.append(cmd)
            if cmd == .reload(items: [track]) {
                expect.fulfill()
            }
        }
        
        sut.dispatch(.willDraggBegin)
        sut.audio(player: AVQueuePlayer(), reload: track)
        XCTAssertTrue(cmds.isEmpty)
        
        sut.dispatch(.didDraggEnd)
        wait(for: [expect], timeout: 0.1)
        XCTAssertEqual(cmds, [.reload(items: [track])])
    }

    @MainActor
    func testAudioObserver_onBlockingEvents_togglesUserInteractionCommands() {
        let cmds = captureViewModelCommands { sut in
            sut.audioPlayerWillStartBlockingAction()
            sut.audioPlayerDidFinishBlockingAction()
        }
        XCTAssertEqual(cmds, [.disableUserInteraction, .enableUserInteraction])
    }
    
    @MainActor
    private func captureViewModelCommands(_ action: (AudioPlaylistViewModel) -> Void) -> [AudioPlaylistViewModel.Command] {
        let sut = makeSUT()
        var cmds: [AudioPlaylistViewModel.Command] = []
        sut.invokeCommand = { cmds.append($0) }
        action(sut)
        return cmds
    }

    @MainActor
    func testDispatch_onDidSelectAndDidDeselect_togglesToolbarVisibility() {
        let item = AudioPlayerItem.mockItem
        
        let selectCmds = captureViewModelCommands { sut in
            sut.dispatch(.didSelect(item))
        }
        XCTAssertEqual(selectCmds, [.showToolbar])
        
        let deselectCmds = captureViewModelCommands { sut in
            sut.dispatch(.didDeselect(item))
        }
        XCTAssertEqual(deselectCmds, [.hideToolbar])
    }
    
    @MainActor
    func testDispatch_onRemoveSelectedItems_clearsSelectionAndTracksEvent() {
        let sut = makeSUT(tracker: tracker)
        var cmds: [AudioPlaylistViewModel.Command] = []
        sut.invokeCommand = { cmds.append($0) }
        
        let i1 = AudioPlayerItem.mockItem
        let i2 = AudioPlayerItem.mockItem
        sut.dispatch(.didSelect(i1))
        sut.dispatch(.didSelect(i2))
        cmds.removeAll()
        
        sut.dispatch(.removeSelectedItems)
        XCTAssertEqual(cmds, [.deselectAll, .hideToolbar])
        XCTAssertEqual(playerHandler.onDeleteItems_calledTimes, 1)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueItemRemovedEvent()]
        )
    }
}
