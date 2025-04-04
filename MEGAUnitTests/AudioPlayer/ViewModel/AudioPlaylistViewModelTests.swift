@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGASDKRepoMock
import XCTest

final class AudioPlaylistViewModelTests: XCTestCase {
    private let playerHandler = MockAudioPlayerHandler()
    private var anyAudioNode: MockNode {
        MockNode(handle: 1, name: "first-audio.mp3", nodeType: .file)
    }
    
    @MainActor
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        router: (any AudioPlaylistViewRouting)? = nil,
        tracker: (any AnalyticsTracking)? = nil
    ) -> AudioPlaylistViewModel {
        let router = router ?? MockAudioPlaylistViewRouter()
        let tracker = tracker ?? MockTracker()
        let sut = AudioPlaylistViewModel(configEntity: configEntity, router: router, tracker: tracker)
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: #filePath, line: #line)
        return sut
    }
    
    private func audioPlayerConfigEntity(
        node: MockNode,
        isFolderLink: Bool = false,
        fileLink: String? = nil
    ) -> AudioPlayerConfigEntity {
        AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            playerHandler: playerHandler
        )
    }
    
    @MainActor
    func testAudioPlayerActions() throws {
        let mockPlayerCurrentItem = AudioPlayerItem.mockItem
        playerHandler.mockPlayerCurrentItem = mockPlayerCurrentItem
        let config = AudioPlayerConfigEntity(parentNode: MEGANode(), playerHandler: playerHandler)
        let tracker = MockTracker()
        let sut = makeSUT(configEntity: config, tracker: tracker)
        
        test(
            viewModel: sut,
            action: .onViewDidLoad,
            expectedCommands: [
                .reloadTracks(currentItem: mockPlayerCurrentItem, queue: nil, selectedIndexPaths: []),
                .title(title: "")
            ]
        )
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        
        test(
            viewModel: sut,
            action: .move(mockPlayerCurrentItem, IndexPath(row: 1, section: 0), .up),
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.onMoveItem_calledTimes, 1)
        
        test(viewModel: sut, action: .didSelect(mockPlayerCurrentItem), expectedCommands: [.showToolbar])
        
        test(viewModel: sut, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar])
        XCTAssertEqual(playerHandler.onDeleteItems_calledTimes, 1)
        
        test(viewModel: sut, action: .didDeselect(mockPlayerCurrentItem), expectedCommands: [.hideToolbar])
        
        test(viewModel: sut, action: .onViewWillDisappear, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        test(viewModel: sut, action: .willDraggBegin, expectedCommands: [])
        let file1URL = try XCTUnwrap(Bundle.main.url(forResource: "incoming_voice_video_call_iOS9", withExtension: "mp3"))
        let track1 = AudioPlayerItem(name: "file 1", url: file1URL, node: nil)
        sut.audio(player: AVQueuePlayer(), reload: track1)
        test(viewModel: sut, action: .didDraggEnd, expectedCommands: [.reload(items: [track1])])
    }
    
    @MainActor
    func testRouterActions() {
        let config = AudioPlayerConfigEntity(
            parentNode: MEGANode(),
            playerHandler: playerHandler
        )
        let router = MockAudioPlaylistViewRouter()
        let sut = makeSUT(
            configEntity: config,
            router: router
        )
        
        test(viewModel: sut, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    @MainActor
    func testAnalytics_onMove_shouldTrackReorderEvent() {
        let tracker = MockTracker()
        let config = audioPlayerConfigEntity(node: anyAudioNode)
        let sut = makeSUT(
            configEntity: config,
            tracker: tracker
        )
        
        let movedItem = AudioPlayerItem.mockItem
        sut.dispatch(.move(movedItem, IndexPath(row: 1, section: 0), .up))
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueReorderedEvent()]
        )
    }
    
    @MainActor
    func testAnalytics_onRemoveSelectedItems_shouldTrackRemoveTracksEvent() {
        let tracker = MockTracker()
        let config = audioPlayerConfigEntity(node: anyAudioNode)
        let sut = makeSUT(
            configEntity: config,
            tracker: tracker
        )
        
        sut.dispatch(.removeSelectedItems)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueItemRemovedEvent()]
        )
    }
}
