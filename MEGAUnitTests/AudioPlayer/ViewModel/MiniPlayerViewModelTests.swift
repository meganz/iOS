@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAFoundation
import MEGASDKRepoMock
import XCTest

final class MiniPlayerViewModelTests: XCTestCase {
    
    @MainActor
    func testAudioPlayerActions() async {
        let (viewModel, _, mockPlayerHandler, _, _, _) = makeSUT()
        
        await test(viewModel: viewModel, action: .onPlayPause, expectedCommands: [])
        XCTAssertEqual(mockPlayerHandler.togglePlay_calledTimes, 1)
        
        await test(viewModel: viewModel, action: .playItem(AudioPlayerItem.mockItem), expectedCommands: [])
        XCTAssertEqual(mockPlayerHandler.playItem_calledTimes, 1)
        
        await test(viewModel: viewModel, action: .deinit, expectedCommands: [])
        XCTAssertEqual(mockPlayerHandler.removePlayerListener_calledTimes, 1)
    }

    @MainActor
    func testDispatch_onViewDidLoadWhenPlayerAlreadyInitialized_configuresPlayerProperly() {
        let (viewModel, _, mockPlayerHandler, _, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        viewModel.invokeCommand = { receivedCommands.append($0) }
        
        viewModel.dispatch(.onViewDidLoad)
        
        XCTAssertEqual(receivedCommands, [
            .showLoading(false),
            .initTracks(currentItem: AudioPlayerItem.mockItem, queue: nil, loopMode: false)
        ])
        XCTAssertEqual(mockPlayerHandler.addPlayerListener_calledTimes, 1)
        XCTAssertEqual(mockPlayerHandler.refreshCurrentItemState_calledTimes, 1)
    }
    
    @MainActor
    func testDispatch_onViewDidLoadWhenPlayerShouldInitialized_preparePlayerOfflineDismissViewWhenInvalidOfflinePaths() {
        let (viewModel, mockRouter, _, _, _, _) = makeSUT(playerType: .offline, shouldInitializePlayer: true, relatedFileLinks: ["non-related-file-link"])
        
        let expectation = XCTestExpectation(description: #function)
        
        mockRouter.onDismissCompletion = {
            expectation.fulfill()
        }
        
        viewModel.dispatch(.onViewDidLoad)
        
        wait(for: [expectation], timeout: 3)
        
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
    }
    
    @MainActor
    func testDispatch_onViewDidLoadWhenPlayerShouldInitialized_preparePlayerOfflineInitializeTracks() {
        let (viewModel, mockRouter, mockPlayerHandler, _, _, _) = makeSUT(playerType: .offline, shouldInitializePlayer: true, relatedFileLinks: ["/examples/mp3/SoundHelix-Song-1.mp3"])
        
        let expectation = XCTestExpectation(description: #function)
        expectation.expectedFulfillmentCount = 4
        
        mockPlayerHandler.onAutoPlayCompletion = { expectation.fulfill() }
        mockPlayerHandler.onAddPlayerTracksCompletion = { expectation.fulfill() }
        mockPlayerHandler.onAddPlayerListenerCompletion = { expectation.fulfill() }
        mockPlayerHandler.onRefreshCurrentItemStateCompletion = { expectation.fulfill() }
        
        viewModel.dispatch(.onViewDidLoad)
        
        wait(for: [expectation], timeout: 1)
    }
    
    @MainActor
    func testDispatch_onViewDidLoadWhenPlayerTypeNonOffline_dismissViewWhenNoNode() {
        PlayerType.allCases
            .enumerated()
            .filter { $1 != .offline }
            .forEach { (_, playerType) in
                
                let (viewModel, mockRouter, _, _, _, _) = makeSUT(playerType: playerType, shouldInitializePlayer: true, relatedFileLinks: ["/examples/mp3/SoundHelix-Song-1.mp3"])
                
                let expectation = XCTestExpectation()
                
                mockRouter.onDismissCompletion = { expectation.fulfill() }
                
                viewModel.dispatch(.onViewDidLoad)
                
                wait(for: [expectation], timeout: 1)
            }
    }
    
    @MainActor
    func testDispatch_onViewDidLoadWhenPlayerTypeNonOffline_initializePlayer() {
        PlayerType.allCases
            .enumerated()
            .filter { $1 != .offline }
            .forEach { (_, playerType) in
                
                let (viewModel, _, mockPlayerHandler, _, _, streamingInfoUseCase) = makeSUT(node: MockNode(handle: 1), playerType: playerType, shouldInitializePlayer: true, relatedFileLinks: ["/examples/mp3/SoundHelix-Song-1.mp3"])
                
                let expectation = XCTestExpectation()
                expectation.expectedFulfillmentCount = 4
                
                mockPlayerHandler.onAutoPlayCompletion = { expectation.fulfill() }
                mockPlayerHandler.onAddPlayerTracksCompletion = { expectation.fulfill() }
                mockPlayerHandler.onAddPlayerListenerCompletion = { expectation.fulfill() }
                mockPlayerHandler.onRefreshCurrentItemStateCompletion = { expectation.fulfill() }
                
                streamingInfoUseCase.completeInfoNode(with: .mockItem)
                
                viewModel.dispatch(.onViewDidLoad)
                
                wait(for: [expectation], timeout: 1)
            }
    }
    
    @MainActor func testDispatch_deinit_logoutFolderLink() async {
        let (viewModel, _, _, _, mockNodeInfouseCase, _) = makeSUT(playerType: .folderLink, isRouterFolderLinkPresenter: false)
        
        await test(viewModel: viewModel, action: .deinit, expectedCommands: [])
        
        XCTAssertEqual(mockNodeInfouseCase.folderLinkLogout_callTimes, 1)
    }
    
    @MainActor
    func testDispatch_showPlayerAllCases_removePlayerListener() async {
        for (index, playerType) in PlayerType.allCases.enumerated() {
            let (viewModel, _, mockPlayerHandler, _, _, _) = makeSUT(playerType: playerType)
            
            await test(viewModel: viewModel, action: .showPlayer(nil, nil), expectedCommands: [])
            
            XCTAssertEqual(mockPlayerHandler.removePlayerListener_calledTimes, 1, "Expect to remove player listener player, but failed instead at index: \(index) with playerType: \(playerType)")
        }
    }
    
    @MainActor func testDispatch_showPlayerWithDefaultPlayerType_showsFullScreenPlayer() async {
        let (viewModel, mockRouter, _, _, _, _) = makeSUT()
        
        await test(viewModel: viewModel, action: .showPlayer(MockNode(handle: 1), nil), expectedCommands: [])
        
        XCTAssertEqual(mockRouter.showPlayer_calledTimes, 1)
    }
    
    @MainActor
    func testDispatch_showPlayerWithNonDefaultPlayerType_showsFullScreenPlayer() async {
        for (index, playerType) in PlayerType.allCases.enumerated().filter({ $1 != .default }) {
            
            let (viewModel, mockRouter, _, _, _, _) = makeSUT(playerType: playerType)
            
            await test(viewModel: viewModel, action: .showPlayer(nil, nil), expectedCommands: [])
            
            XCTAssertEqual(mockRouter.showPlayer_calledTimes, 1, "Expect to show full screen player, but failed instead at index: \(index) with playerType: \(playerType)")
        }
    }
    
    @MainActor func testDispatch_onClose_stopStreamignInfoServer() async {
        let (viewModel, _, _, _, _, mockStreamingInfoUseCase) = makeSUT()
        
        await test(viewModel: viewModel, action: .onClose, expectedCommands: [])
        
        XCTAssertEqual(mockStreamingInfoUseCase.stopServer_calledTimes, 1)
    }
    
    @MainActor func testDispatch_onClose_dismissView() async {
        let (viewModel, mockRouter, _, _, _, _) = makeSUT()
        
        await test(viewModel: viewModel, action: .onClose, expectedCommands: [])
        
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
    }
    
    @MainActor func testDispatch_onCloseWithFolderLinkWhenFolderLinkAndPresenterIsNotFolderLink_logoutFolderLink() async {
        let (viewModel, _, _, _, mockNodeInfoUseCase, _) = makeSUT(playerType: .folderLink, isRouterFolderLinkPresenter: false)
        
        await test(viewModel: viewModel, action: .onClose, expectedCommands: [])
        
        XCTAssertEqual(mockNodeInfoUseCase.folderLinkLogout_callTimes, 1)
    }
    
    @MainActor
    func testAudioDidStartPlayingItem_shouldResumePlayback_whenStatusNotStartFromBeginning() {
        func assert(
            whenContinuationStatus continuationStatus: PlaybackContinuationStatusEntity,
            expectedPlayerResumePlaybackCalls: [TimeInterval],
            line: UInt = #line
        ) {
            let (viewModel, _, mockPlayerHandler, mockPlaybackContinuationUseCase, _, _) = makeSUT()
            mockPlaybackContinuationUseCase._status = continuationStatus
            
            viewModel.audioDidStartPlayingItem(testItem)
            
            XCTAssertEqual(
                mockPlayerHandler.playerResumePlayback_Calls,
                expectedPlayerResumePlaybackCalls,
                line: line
            )
        }
        
        assert(
            whenContinuationStatus: .startFromBeginning,
            expectedPlayerResumePlaybackCalls: []
        )
        assert(
            whenContinuationStatus: .displayDialog(playbackTime: 1234.0),
            expectedPlayerResumePlaybackCalls: [1234.0]
        )
        assert(
            whenContinuationStatus: .resumeSession(playbackTime: 3456.0),
            expectedPlayerResumePlaybackCalls: [3456.0]
        )
    }
    
    @MainActor
    func testDispatch_whenPlayItemWithCurrentRepeatModeIsRepeatOne_PlayItemWithRepeatsAll() {
        let itemToPlay: AudioPlayerItem = .mockItem
        let (sut, _, mockPlayerHandler, _, _, _) = makeSUT()
        mockPlayerHandler.setCurrentRepeatMode(.repeatOne)
        
        sut.dispatch(.playItem(itemToPlay))
        
        XCTAssertEqual(mockPlayerHandler.onRepeatAll_calledTimes, 1)
        XCTAssertEqual(mockPlayerHandler.playItem_calledTimes, 1)
    }
    
    @MainActor
    func testDispatch_whenPlayItemWithCurrentRepeatModeIsNonRepeatOne_PlayItemWithoutRepeatsAll() {
        RepeatMode.allCases.enumerated()
            .filter { $1 != .repeatOne }
            .forEach { (index, repeatMode) in
                let itemToPlay: AudioPlayerItem = .mockItem
                let (sut, _, mockPlayerHandler, _, _, _) = makeSUT()
                mockPlayerHandler.setCurrentRepeatMode(repeatMode)
                
                sut.dispatch(.playItem(itemToPlay))
                
                XCTAssertEqual(mockPlayerHandler.onRepeatAll_calledTimes, 0, "Expect to not call repeat with mode: \(repeatMode) at index: \(index)")
                XCTAssertEqual(mockPlayerHandler.playItem_calledTimes, 1, "Expect to call play item with mode: \(repeatMode) at index: \(index)")
            }
    }
    
    // MARK: - Test Helpers
    
    @MainActor
    private func makeSUT(
        node: MockNode? = nil,
        playerType: PlayerType = .default,
        shouldInitializePlayer: Bool = false,
        isRouterFolderLinkPresenter: Bool = true,
        relatedFileLinks: [String] = [],
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: MiniPlayerViewModel,
        router: MockMiniPlayerViewRouter,
        playerHandler: MockAudioPlayerHandler,
        playbackContinuationUseCase: MockPlaybackContinuationUseCase,
        nodeInfouseCase: MockNodeInfoUseCase,
        mockStreamingInfoUseCase: MockStreamingInfoUseCase
    ) {
        let mockRouter = MockMiniPlayerViewRouter(isFolderLinkPresenter: isRouterFolderLinkPresenter)
        let mockPlayerHandler = MockAudioPlayerHandler()
        let mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
        let mockNodeInfoUseCase = MockNodeInfoUseCase()
        let mockStreamingInfoUseCase = MockStreamingInfoUseCase()
        let mockAudioPlayerUseCase = MockAudioPlayerUseCase()
        
        let sut = MiniPlayerViewModel(
            configEntity: audioPlayerConfigEntity(
                node: node,
                playerType: playerType,
                mockPlayerHandler: mockPlayerHandler,
                shouldInitializePlayer: shouldInitializePlayer,
                relatedFileLinks: relatedFileLinks
            ),
            router: mockRouter,
            nodeInfoUseCase: mockNodeInfoUseCase,
            streamingInfoUseCase: mockStreamingInfoUseCase,
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: mockPlaybackContinuationUseCase,
            audioPlayerUseCase: mockAudioPlayerUseCase
        )
        
        return (sut, mockRouter, mockPlayerHandler, mockPlaybackContinuationUseCase, mockNodeInfoUseCase, mockStreamingInfoUseCase)
    }
    
    private func audioPlayerConfigEntity(
        node: MockNode? = nil,
        playerType: PlayerType = .default,
        mockPlayerHandler: MockAudioPlayerHandler,
        shouldInitializePlayer: Bool,
        relatedFileLinks: [String]
    ) -> AudioPlayerConfigEntity {
        
        switch playerType {
        case .default:
            return AudioPlayerConfigEntity(
                node: node,
                isFolderLink: false,
                fileLink: nil,
                relatedFiles: nil,
                playerHandler: mockPlayerHandler,
                shouldResetPlayer: shouldInitializePlayer
            )
        case .folderLink:
            return AudioPlayerConfigEntity(
                node: node,
                isFolderLink: true,
                fileLink: nil,
                relatedFiles: nil,
                playerHandler: mockPlayerHandler,
                shouldResetPlayer: shouldInitializePlayer
            )
        case .fileLink:
            return AudioPlayerConfigEntity(
                node: node,
                isFolderLink: false,
                fileLink: "any-file-link",
                relatedFiles: nil,
                playerHandler: mockPlayerHandler,
                shouldResetPlayer: shouldInitializePlayer
            )
        case .offline:
            return AudioPlayerConfigEntity(
                node: node,
                isFolderLink: false,
                fileLink: relatedFileLinks.first ?? nil,
                relatedFiles: relatedFileLinks,
                playerHandler: mockPlayerHandler,
                shouldResetPlayer: shouldInitializePlayer
            )
        }
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: "test-name",
            url: URL(string: "any-url")!,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
    
}

extension MiniPlayerViewModel.Command: CustomStringConvertible {
    public var description: String {
        switch self {
        case .showLoading(let isLoading):
            return "Command.showLoading(\(isLoading))"
        case .initTracks(let currentItem, let queue, let loopMode):
            return "MiniPlayerViewModel.Command.initTracks(currentItem: \(currentItem), queue: \(String(describing: queue)), loopMode: \(loopMode))"
        case .reloadNodeInfo(let thumbnail):
            return "Command.reloadNodeInfo(thumbnail: \(thumbnail.map { "<\(String(describing: $0))>" } ?? "nil"))"
        case .reloadPlayerStatus(let percentage, let isPlaying):
            return "Command.reloadPlayerStatus(\(percentage)-isPlaying:\(isPlaying)"
        case .change(let currentItem, let indexPath):
            return "Command.change(\(currentItem)-indexPath:\(indexPath)"
        case .reload(let currentItem):
            return "Command.reload(\(currentItem))"
        case .enableUserInteraction(let enabled):
            return "Command.enableUserInteraction(\(enabled))"
        }
    }
}
