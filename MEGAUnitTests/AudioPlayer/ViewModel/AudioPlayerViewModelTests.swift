import XCTest
import MEGADomain
import MEGADomainMock
import MEGADataMock
@testable import MEGA

final class AudioPlayerViewModelTests: XCTestCase {
    
    let router = MockAudioPlayerViewRouter()
    let playerHandler = MockAudioPlayerHandler()
    
    lazy var mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()

    lazy var onlineViewModel = makeSUT(
        configEntity: AudioPlayerConfigEntity(
            node: MEGANode(),
            isFolderLink: false,
            fileLink: "",
            playerHandler: playerHandler
        ),
        nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
        streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository())
    )
    
    lazy var offlineViewModel = makeSUT(
        configEntity: AudioPlayerConfigEntity(
            fileLink: "file_path",
            playerHandler: playerHandler
        ),
        offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository())
    )
    
    func testPlaybackActions() {
        test(viewModel: onlineViewModel, action: .onViewDidLoad, expectedCommands: [.showLoading(true),
                                                                              .configureFileLinkPlayer(title: "Track 5", subtitle: Strings.Localizable.fileLink),
                                                                              .updateShuffle(status: playerHandler.isShuffleEnabled()),
                                                                              .updateSpeed(mode: .normal)], timeout: 0.5)
        
        test(viewModel: onlineViewModel, action: .updateCurrentTime(percentage: 0.2), expectedCommands: [])
        XCTAssertEqual(playerHandler.updateProgressCompleted_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .progressDragEventBegan, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventBeganCalledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .progressDragEventEnded, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventEndedCalledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onShuffle(active: true), expectedCommands: [])
        XCTAssertEqual(playerHandler.onShuffle_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onPlayPause, expectedCommands: [])
        XCTAssertEqual(playerHandler.togglePlay_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onGoBackward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goBackward_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onPrevious, expectedCommands: [])
        XCTAssertEqual(playerHandler.playPrevious_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onNext, expectedCommands: [])
        XCTAssertEqual(playerHandler.playNext_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onGoForward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goForward_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .loop)])
        XCTAssertEqual(playerHandler.onRepeatAll_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .repeatOne)])
        XCTAssertEqual(playerHandler.onRepeatOne_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)])
        XCTAssertEqual(playerHandler.onRepeatDisabled_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .deinit, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .oneAndAHalf)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .double)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 2)
        
        test(viewModel: onlineViewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .half)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 3)
        
        test(viewModel: onlineViewModel, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .normal)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 4)
    }
    
    func testRouterActions() {
        test(viewModel: onlineViewModel, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .showPlaylist, expectedCommands: [])
        XCTAssertEqual(router.goToPlaylist_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
        
        test(viewModel: offlineViewModel, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 2)
        
        test(viewModel: onlineViewModel, action: .`import`, expectedCommands: [])
        XCTAssertEqual(router.importNode_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .share(sender: nil), expectedCommands: [])
        XCTAssertEqual(router.share_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .sendToChat, expectedCommands: [])
        XCTAssertEqual(router.sendToContact_calledTimes, 1)
        
        test(viewModel: onlineViewModel, action: .showActionsforCurrentNode(sender: UIButton()), expectedCommands: [])
        XCTAssertEqual(router.showAction_calledTimes, 1)
    }
    
    func testOnReceiveAudioPlayerActions_shouldInvokeCorrectCommands() {
        var invokedCommands =  [AudioPlayerViewModel.Command]()
        onlineViewModel.invokeCommand = { invokedCommands.append($0) }
        
        mockPlaybackContinuationUseCase._status = .startFromBeginning
        onlineViewModel.audioDidStartPlayingItem(testItem)
        XCTAssertEqual(invokedCommands, [])
        
        mockPlaybackContinuationUseCase._status = .displayDialog(playbackTime: 1234.0)
        onlineViewModel.audioDidStartPlayingItem(testItem)
        XCTAssertEqual(invokedCommands, [.displayPlaybackContinuationDialog(fileName: testItem.name, playbackTime: 1234.0)])
    }
    
    func testAudioPlaybackContinuation_resumeSession() {
        mockPlaybackContinuationUseCase._status = .resumeSession(playbackTime: 1234.0)
        
        onlineViewModel.audioDidStartPlayingItem(testItem)
        
        XCTAssertEqual(
            playerHandler.playerResumePlayback_Calls,
            [1234.0]
        )
    }
    
    func testSelectPlaybackContinuationDialog_shouldSetPreference() {
        onlineViewModel.dispatch(.onSelectResumePlaybackContinuationDialog(playbackTime: 1234.0))
        
        XCTAssertEqual(
            mockPlaybackContinuationUseCase.setPreference_Calls,
            [.resumePreviousSession]
        )
        
        onlineViewModel.dispatch(.onSelectRestartPlaybackContinuationDialog)
        
        XCTAssertEqual(
            mockPlaybackContinuationUseCase.setPreference_Calls,
            [.resumePreviousSession, .restartFromBeginning]
        )
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        nodeInfoUseCase: NodeInfoUseCaseProtocol? = nil,
        streamingInfoUseCase: StreamingInfoUseCaseProtocol? = nil,
        offlineInfoUseCase: OfflineFileInfoUseCaseProtocol? = nil
    ) -> AudioPlayerViewModel {
        AudioPlayerViewModel(
            configEntity: configEntity,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: streamingInfoUseCase,
            offlineInfoUseCase: offlineInfoUseCase,
            playbackContinuationUseCase: mockPlaybackContinuationUseCase,
            dispatchQueue: MockDispatchQueue()
        )
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: "test-name",
            url: URL(string: "any-url")!,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
}
