@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAFoundation
import Testing
import XCTest

@MainActor
enum MiniPlayerTestFactory {
    static func makeSUT(
        node: MockNode? = nil,
        playerType: PlayerType = .default,
        shouldInitializePlayer: Bool = false,
        isRouterFolderLinkPresenter: Bool = true,
        relatedFileLinks: [String] = []
    ) -> (
        sut: MiniPlayerViewModel,
        router: MockMiniPlayerViewRouter,
        playerHandler: MockAudioPlayerHandler,
        playbackContinuationUseCase: MockPlaybackContinuationUseCase,
        nodeInfoUseCase: MockNodeInfoUseCase,
        streamingInfoUseCase: MockStreamingInfoUseCase
    ) {
        let router = MockMiniPlayerViewRouter(isFolderLinkPresenter: isRouterFolderLinkPresenter)
        let playerHandler = MockAudioPlayerHandler()
        let playbackContinuationUseCase = MockPlaybackContinuationUseCase()
        let nodeInfoUseCase = MockNodeInfoUseCase()
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        let audioPlayerUseCase = MockAudioPlayerUseCase()
        
        let sut = MiniPlayerViewModel(
            configEntity: makeConfig(
                node: node,
                playerType: playerType,
                shouldInitializePlayer: shouldInitializePlayer,
                relatedFileLinks: relatedFileLinks
            ),
            playerHandler: playerHandler,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: streamingInfoUseCase,
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: playbackContinuationUseCase,
            audioPlayerUseCase: audioPlayerUseCase
        )
        return (sut, router, playerHandler, playbackContinuationUseCase, nodeInfoUseCase, streamingInfoUseCase)
    }
    
    static func makeConfig(
        node: MockNode? = nil,
        playerType: PlayerType,
        shouldInitializePlayer: Bool,
        relatedFileLinks: [String]
    ) -> AudioPlayerConfigEntity {
        let isFolderLink = playerType == .folderLink
        let fileLink: String?
        let relatedFiles: [String]?
        switch playerType {
        case .fileLink:
            fileLink = "any-file-link"
            relatedFiles = nil
        case .offline:
            fileLink = relatedFileLinks.first
            relatedFiles = relatedFileLinks
        default:
            fileLink = nil
            relatedFiles = nil
        }
        return AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            relatedFiles: relatedFiles,
            shouldResetPlayer: shouldInitializePlayer
        )
    }
}

@MainActor
struct MiniPlayerViewModelTestsSuite {
    @Suite("Action handling and playback control")
    @MainActor struct ActionTests {
        @Test
        func testOnPlayPause_togglesPlay() async {
            let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
            sut.dispatch(.onPlayPause)
            #expect(playerHandler.togglePlay_calledTimes == 1)
        }
        
        @Test
        func testPlayItem_invokesPlayItem() async {
            let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
            sut.dispatch(.playItem(.mockItem))
            #expect(playerHandler.playItem_calledTimes == 1)
        }
        
        @Test
        func testOnClose_removesPlayerListener() async {
            let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
            sut.dispatch(.onClose)
            #expect(playerHandler.removePlayerListener_calledTimes == 1)
        }
    }
    
    @Suite("Closing the mini player and cleanup")
    @MainActor struct CloseTests {
        @Test
        func testDispatch_onClose_stopStreamignInfoServer() async {
            let (sut, _, _, _, _, streamingInfoUseCase) = MiniPlayerTestFactory.makeSUT()
            sut.dispatch(.onClose)
            #expect(streamingInfoUseCase.stopServer_calledTimes == 1)
        }
        
        @Test
        func testDispatch_onClose_dismissView() async {
            let (sut, router, _, _, _, _) = MiniPlayerTestFactory.makeSUT()
            sut.dispatch(.onClose)
            #expect(router.dismiss_calledTimes == 1)
        }
        
        @Test
        func testDispatch_onCloseWithFolderLinkWhenFolderLinkAndPresenterIsNotFolderLink_logoutFolderLink() async {
            let (sut, router, _, _, nodeInfoUseCase, _) = MiniPlayerTestFactory.makeSUT(
                playerType: .folderLink,
                isRouterFolderLinkPresenter: false
            )
            sut.dispatch(.onClose)
            #expect(router.dismiss_calledTimes == 1)
            #expect(nodeInfoUseCase.folderLinkLogout_callTimes == 1)
        }
    }
    
    @Suite("Playback repeat mode behavior")
    @MainActor struct PlaybackRepeatTests {
        @Test
        func testDispatch_whenPlayItemWithCurrentRepeatModeIsRepeatOne_playItemWithRepeatsAll() async {
            let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
            playerHandler.setCurrentRepeatMode(.repeatOne)
            sut.dispatch(.playItem(.mockItem))
            #expect(playerHandler.onRepeatAll_calledTimes == 1)
            #expect(playerHandler.playItem_calledTimes == 1)
        }
        
        @Test(arguments: RepeatMode.allCases.filter { $0 != .repeatOne })
        func testDispatch_whenPlayItemWithCurrentRepeatModeIsNonRepeatOne_playItemWithoutRepeatsAll(_ repeatMode: RepeatMode) async {
            let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
            playerHandler.setCurrentRepeatMode(repeatMode)
            sut.dispatch(.playItem(.mockItem))
            #expect(playerHandler.onRepeatAll_calledTimes == 0)
            #expect(playerHandler.playItem_calledTimes == 1)
        }
    }
    
    @Suite("Presenting the full-screen player")
    @MainActor struct ShowPlayerTests {
        @Test(arguments: PlayerType.allCases)
        func testDispatch_showPlayer_showsFullScreenPlayer(type: PlayerType) async {
            let (sut, router, _, _, _, _) = MiniPlayerTestFactory.makeSUT(playerType: type)
            sut.dispatch(.showPlayer(MockNode(handle: 1), nil))
            #expect(router.showPlayer_calledTimes == 1)
        }
    }
}

@MainActor
final class MiniPlayerViewModelTests: XCTestCase {
    func testDispatch_onViewDidLoadWhenPlayerAlreadyInitialized_configuresPlayerProperly() {
        let mockCurrentPlayerItem = AudioPlayerItem.mockItem
        let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
        playerHandler.mockPlayerCurrentItem = mockCurrentPlayerItem
        
        test(
            viewModel: sut,
            actions: [.onViewDidLoad],
            expectedCommands: [
                .showLoading(false),
                .initTracks(currentItem: mockCurrentPlayerItem, queue: nil, loopMode: false)
            ],
            timeout: 1
        )
        
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        XCTAssertEqual(playerHandler.refreshCurrentItemState_calledTimes, 1)
    }
    
    func testDispatch_onViewDidLoadWhenPlayerShouldInitialized_preparePlayerOfflineInitializeTracks() {
        let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT(
            playerType: .offline,
            shouldInitializePlayer: true,
            relatedFileLinks: ["/examples/mp3/SoundHelix-Song-1.mp3"]
        )
        let exp = XCTestExpectation(description: #function)
        exp.expectedFulfillmentCount = 2
        playerHandler.onAddPlayerTracksCompletion = { exp.fulfill() }
        playerHandler.onAddPlayerListenerCompletion = { exp.fulfill() }
        
        sut.dispatch(.onViewDidLoad)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testDispatch_onViewDidLoadWhenPlayerShouldInitialized_preparePlayerOfflineDismissViewWhenInvalidOfflinePaths() {
        let (viewModel, mockRouter, _, _, _, _) = MiniPlayerTestFactory.makeSUT(
            playerType: .offline,
            shouldInitializePlayer: true,
            relatedFileLinks: ["non-related-file-link"]
        )
        let exp = XCTestExpectation(description: #function)
        mockRouter.onDismissCompletion = { exp.fulfill() }
        
        viewModel.dispatch(.onViewDidLoad)
        
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
    }
    
    func testUpdateConfig_whenShouldResetPlayerIsFalse_reusesExistingPlayer() {
        let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
        let existingItem = AudioPlayerItem.mockItem
        playerHandler.mockPlayerCurrentItem = existingItem
        
        test(
            viewModel: sut,
            actions: [.refresh(MiniPlayerTestFactory.makeConfig(node: nil, playerType: .default, shouldInitializePlayer: false, relatedFileLinks: []))],
            expectedCommands: [.showLoading(false), .initTracks(currentItem: existingItem, queue: nil, loopMode: false)],
            timeout: 1
        )
        
        XCTAssertEqual(playerHandler.addPlayerListener_calledTimes, 1)
        XCTAssertEqual(playerHandler.refreshCurrentItemState_calledTimes, 1)
    }
    
    func testUpdateConfig_whenShouldResetPlayerIsTrue_resetsPlayerBeforePreparing() {
        let (sut, _, playerHandler, _, _, _) = MiniPlayerTestFactory.makeSUT()
        
        test(
            viewModel: sut,
            actions: [.refresh(MiniPlayerTestFactory.makeConfig(node: nil, playerType: .default, shouldInitializePlayer: true, relatedFileLinks: []))],
            expectedCommands: [.showLoading(true)],
            timeout: 1
        )
        
        XCTAssertEqual(playerHandler.resettingAudioPlayer_calledTimes, 1)
    }
}
