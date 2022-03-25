import XCTest
@testable import MEGA

final class AudioPlayerViewModelTests: XCTestCase {
    
    let router = MockAudioPlayerViewRouter()
    let playerHandler = MockAudioPlayerHandler()

    lazy var viewModel = AudioPlayerViewModel(node: MEGANode(),
                                              fileLink: "",
                                              isFolderLink: false,
                                              router: router,
                                              playerHandler: playerHandler,
                                              nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
                                              streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
                                              dispatchQueue: MockDispatchQueue())
    
    lazy var offlineViewModel = AudioPlayerViewModel(selectedFile: "file_path",
                                                     filePaths: nil,
                                                     router: router,
                                                     playerHandler: playerHandler,
                                                     offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
                                                     dispatchQueue: MockDispatchQueue())
    
    func testPlaybackActions() {
        test(viewModel: viewModel, action: .onViewDidLoad, expectedCommands: [.showLoading(true),
                                                                              .configureFileLinkPlayer(title: "Track 5", subtitle: Strings.Localizable.fileLink),
                                                                              .updateShuffle(status: playerHandler.isShuffleEnabled()),
                                                                              .updateSpeed(mode: .normal)], timeout: 0.5)
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        XCTAssertEqual(playerHandler.addPlayer_calledTimes, 1)
        XCTAssertEqual(playerHandler.addPlayerTracks_calledTimes, 1)
        
        test(viewModel: viewModel, action: .updateCurrentTime(percentage: 0.2), expectedCommands: [])
        XCTAssertEqual(playerHandler.updateProgressCompleted_calledTimes, 1)
        
        test(viewModel: viewModel, action: .progressDragEventBegan, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventBeganCalledTimes, 1)
        
        test(viewModel: viewModel, action: .progressDragEventEnded, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventEndedCalledTimes, 1)
        
        test(viewModel: viewModel, action: .onShuffle(active: true), expectedCommands: [])
        XCTAssertEqual(playerHandler.onShuffle_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onPlayPause, expectedCommands: [])
        XCTAssertEqual(playerHandler.togglePlay_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onGoBackward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goBackward_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onPrevious, expectedCommands: [])
        XCTAssertEqual(playerHandler.playPrevious_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onNext, expectedCommands: [])
        XCTAssertEqual(playerHandler.playNext_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onGoForward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goForward_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onRepeatPressed, expectedCommands:[.updateRepeat(status: .loop)])
        XCTAssertEqual(playerHandler.onRepeatAll_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .repeatOne)])
        XCTAssertEqual(playerHandler.onRepeatOne_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)])
        XCTAssertEqual(playerHandler.onRepeatDisabled_calledTimes, 1)
        
        test(viewModel: viewModel, action: .deinit, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .oneAndAHalf)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .double)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 2)
        
        test(viewModel: viewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .half)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 3)
        
        test(viewModel: viewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .normal)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 4)
    }
    
    func testRouterActions() {
        test(viewModel: viewModel, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        
        test(viewModel: viewModel, action: .showPlaylist, expectedCommands: [])
        XCTAssertEqual(router.goToPlaylist_calledTimes, 1)
        
        test(viewModel: viewModel, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
        
        test(viewModel: offlineViewModel, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(router.showOfflineMiniPlayer_calledTimes, 1)
        
        test(viewModel: viewModel, action: .`import`, expectedCommands: [])
        XCTAssertEqual(router.importNode_calledTimes, 1)
        
        test(viewModel: viewModel, action: .share, expectedCommands: [])
        XCTAssertEqual(router.share_calledTimes, 1)
        
        test(viewModel: viewModel, action: .sendToChat, expectedCommands: [])
        XCTAssertEqual(router.sendToContact_calledTimes, 1)
        
        test(viewModel: viewModel, action: .showActionsforCurrentNode(sender: UIButton()), expectedCommands: [])
        XCTAssertEqual(router.showAction_calledTimes, 1)
    }
}
