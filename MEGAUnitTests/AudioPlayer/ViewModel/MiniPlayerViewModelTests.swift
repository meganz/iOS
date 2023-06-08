import XCTest
@testable import MEGA

final class MiniPlayerViewModelTests: XCTestCase {
    let router = MockMiniPlayerViewRouter()
    let playerHandler = MockAudioPlayerHandler()
    
    lazy var viewModel = MiniPlayerViewModel(configEntity: AudioPlayerConfigEntity(node: nil,
                                                                                   isFolderLink: false,
                                                                                   fileLink: nil,
                                                                                   relatedFiles: nil,
                                                                                   playerHandler: playerHandler),
                                             router: router,
                                             nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
                                             streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
                                             offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()))
    
    func testAudioPlayerActions() {
        test(viewModel: viewModel, action: .onViewDidLoad, expectedCommands: [.showLoading(false),
                                                                             .initTracks(currentItem: AudioPlayerItem.mockItem, queue: nil, loopMode: false)])
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onPlayPause, expectedCommands: [])
        XCTAssertEqual(playerHandler.togglePlay_calledTimes, 1)
        
        test(viewModel: viewModel, action: .playItem(AudioPlayerItem.mockItem), expectedCommands: [])
        XCTAssertEqual(playerHandler.playItem_calledTimes, 1)
        
        test(viewModel: viewModel, action: .deinit, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
    }
    
    func testRouterActions() {
        test(viewModel: viewModel, action: .onClose, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        
        test(viewModel: viewModel, action: .showPlayer(MEGANode(), nil), expectedCommands: [])
        XCTAssertEqual(router.showPlayer_calledTimes, 1)
    }
    
}
