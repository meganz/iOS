@testable import MEGA
import XCTest

final class AudioPlaylistViewModelTests: XCTestCase {
    let router = MockAudioPlaylistViewRouter()
    let playerHandler = MockAudioPlayerHandler()
    
    lazy var viewModel = AudioPlaylistViewModel(configEntity: AudioPlayerConfigEntity(parentNode: MEGANode(), playerHandler: playerHandler),
                                                router: router)
    
    @MainActor func testAudioPlayerActions() throws {
        test(viewModel: viewModel, action: .onViewDidLoad, expectedCommands: [.reloadTracks(currentItem: AudioPlayerItem.mockItem, queue: nil, selectedIndexPaths: []),
                                                                              .title(title: "")])
        
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        
        test(viewModel: viewModel, action: .move(AudioPlayerItem.mockItem, IndexPath(row: 1, section: 0), MovementDirection.up), expectedCommands: [])
        XCTAssertEqual(playerHandler.onMoveItem_calledTimes, 1)
        
        test(viewModel: viewModel, action: .didSelect(AudioPlayerItem.mockItem), expectedCommands: [.showToolbar])
        
        test(viewModel: viewModel, action: .removeSelectedItems, expectedCommands: [.deselectAll, .hideToolbar])
        XCTAssertEqual(playerHandler.onDeleteItems_calledTimes, 1)
        
        test(viewModel: viewModel, action: .didDeselect(AudioPlayerItem.mockItem), expectedCommands: [.hideToolbar])
        
        test(viewModel: viewModel, action: .deinit, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        test(viewModel: viewModel, action: .willDraggBegin, expectedCommands: [])
        let file1URL = try XCTUnwrap(Bundle.main.url(forResource: "incoming_voice_video_call_iOS9", withExtension: "mp3"))
        let track1 = AudioPlayerItem(name: "file 1", url: file1URL, node: nil)
        viewModel.audio(player: AVQueuePlayer(), reload: track1)
        test(viewModel: viewModel, action: .didDraggEnd, expectedCommands: [.reload(items: [track1])])
    }
    
    @MainActor func testRouterActions() {
        test(viewModel: viewModel, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
}
