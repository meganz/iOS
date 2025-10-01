@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATest
import XCTest

@MainActor
final class AudioPlayerViewModelTests: XCTestCase {
    private let shortTimeout: TimeInterval = 0.3
    private let defaultTimeout: TimeInterval = 1.0
    private let playbackTime: TimeInterval = 1234.0
    private let anyURL = URL(string: "any-url")!
    private let offlineURL = URL(string: "offline_file")!
    private let mockTrackURL = URL(string: "www.url.com")!
    private let testItemName = "test-name"
    private let firstAudioName = "first-audio.mp3"
    private let offlineFilePath = "offline_file"
    private var anyAudioNode: MockNode {
        MockNode(handle: 1, name: firstAudioName, nodeType: .file)
    }
    
    func testOnViewDidLoad_fileLinkPlayer_emitsExpectedCommands() async {
        let (sut, _, playerHandler, _) = makeOnlineSUT()
        let expected: [AudioPlayerViewModel.Command] = [
            .showLoading(true),
            .updateShuffle(status: playerHandler.isShuffleEnabled()),
            .updateSpeed(mode: .normal),
            .enableUserInteraction(false, isSingleTrackPlayer: false),
            .configureFileLinkPlayer,
            .forceDisableMultiTrackControls
        ]
        await test(viewModel: sut, action: .onViewDidLoad, expectedCommands: expected, timeout: shortTimeout)
    }
    
    func testUpdateCurrentTime_percentageGiven_progressCompletedCalled_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .updateCurrentTime(percentage: 0.2), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(handler.updateProgressCompleted_calledTimes, 1)
    }
    
    func testOnShuffle_activeTrue_emitsUpdateShuffle() async {
        let (sut, _, _, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onShuffle(active: true), expectedCommands: [.updateShuffle(status: true)], timeout: shortTimeout)
    }
    
    func testOnShuffle_activeTrue_invokesPlayerShuffle_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onShuffle(active: true), expectedCommands: [.updateShuffle(status: true)], timeout: shortTimeout)
        XCTAssertEqual(handler.onShuffle_calledTimes, 1)
    }
    
    func testOnPlayPause_invokesTogglePlay_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onPlayPause, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(handler.togglePlay_calledTimes, 1)
    }
    
    func testOnGoBackward_invokesGoBackward_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onGoBackward, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(handler.goBackward_calledTimes, 1)
    }
    
    func testOnPrevious_invokesPlayPrevious_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onPrevious, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(handler.playPrevious_calledTimes, 1)
    }
    
    func testOnNext_invokesPlayNext_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onNext, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(handler.playNext_calledTimes, 1)
    }
    
    func testOnGoForward_invokesGoForward_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onGoForward, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(handler.goForward_calledTimes, 1)
    }
    
    func testOnRepeatPressed_firstPress_updatesRepeatOne() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .repeatOne)], timeout: shortTimeout)
        XCTAssertEqual(playerHandler.onRepeatOne_calledTimes, 1)
    }
    
    func testOnRepeatPressed_secondPress_updatesRepeatNone() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onRepeatPressed)
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)], timeout: shortTimeout)
        XCTAssertEqual(playerHandler.onRepeatDisabled_calledTimes, 1)
    }
    
    func testOnRepeatPressed_singleItemPlaylist_cyclesBetweenNoneAndRepeatOne() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT(isSingleItemPlaylist: true)
        onlineSUT.dispatch(.onRepeatPressed)
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)], timeout: shortTimeout)
        XCTAssertTrue(playerHandler.isSingleItemPlaylist())
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .repeatOne)], timeout: shortTimeout)
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)], timeout: shortTimeout)
    }
    
    func testRemoveDelegates_invokesRemovePlayerListener_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .removeDelegates, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(handler.removePlayerListener_calledTimes, 1)
    }
    
    func testOnChangeSpeedModePressed_sequence_emitsCorrectSpeeds() async {
        let (sut, _, _, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .oneAndAHalf)], timeout: shortTimeout)
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .double)], timeout: shortTimeout)
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .half)], timeout: shortTimeout)
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .normal)], timeout: shortTimeout)
    }
    
    func testOnChangeSpeedModePressed_firstPress_invokesChangeRate_once() async {
        let (sut, _, handler, _) = makeOnlineSUT()
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .oneAndAHalf)], timeout: shortTimeout)
        XCTAssertEqual(handler.changePlayerRate_calledTimes, 1)
    }
    
    func testRouter_dismiss_invokedOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .dismiss, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    func testRouter_showPlaylist_invokedOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .showPlaylist, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.goToPlaylist_calledTimes, 1)
    }
    
    func testRouter_viewWillDisappear_userDismiss_online_invokesShowMiniPlayerOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    func testRouter_viewWillDisappear_userDismiss_offline_invokesShowMiniPlayerOnce() async {
        let (sut, router) = makeOfflineSUT()
        await test(viewModel: sut, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    func testRouter_initMiniPlayer_invokedOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .initMiniPlayer, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    func testRouter_import_invokedOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .import, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.importNode_calledTimes, 1)
    }
    
    func testRouter_share_invokedOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .share(sender: nil), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.share_calledTimes, 1)
    }
    
    func testRouter_sendToChat_invokedOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .sendToChat, expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.sendToContact_calledTimes, 1)
    }
    
    func testRouter_showActionsForCurrentNode_invokedOnce() async {
        let (sut, _, _, router) = makeOnlineSUT()
        await test(viewModel: sut, action: .showActionsforCurrentNode(sender: UIButton()), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showAction_calledTimes, 1)
    }
    
    func testOnReceiveAudioPlayerActions_startFromBeginning_emitsNoCommands() async {
        let (sut, playbackUseCase, _, _) = makeOnlineSUT()
        playbackUseCase._status = .startFromBeginning
        await test(viewModel: sut, trigger: { sut.audioDidStartPlayingItem(testItem) }, expectedCommands: [], timeout: shortTimeout)
    }
    
    func testAudioStartPlaying_displayDialog_whenAppActive_displaysDialogAndPauses() async {
        let (sut, playbackUseCase, handler, _) = makeOnlineSUT()
        sut.checkAppIsActive = { true }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        let expected: [AudioPlayerViewModel.Command] = [
            .displayPlaybackContinuationDialog(fileName: testItem.name, playbackTime: playbackTime)
        ]
        await test(viewModel: sut, trigger: { sut.audioDidStartPlayingItem(testItem) }, expectedCommands: expected, timeout: shortTimeout)
        XCTAssertEqual(handler.pause_calledTimes, 1)
    }
    
    func testAudioStartPlaying_displayDialog_whenAppNotActive_emitsNoCommands() async {
        let (sut, playbackUseCase, _, _) = makeOnlineSUT()
        sut.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        await test(viewModel: sut, trigger: { sut.audioDidStartPlayingItem(testItem) }, expectedCommands: [], timeout: shortTimeout)
    }
    
    func testAudioStartPlaying_displayDialog_whenAppNotActive_resumesPlayback() async {
        let (sut, playbackUseCase, handler, _) = makeOnlineSUT()
        sut.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        let exp = expectation(description: #function)
        handler.onPlayerResumePlaybackCompletion = { exp.fulfill() }
        await test(viewModel: sut, trigger: { sut.audioDidStartPlayingItem(testItem) }, expectedCommands: [], timeout: shortTimeout)
        await fulfillment(of: [exp], timeout: defaultTimeout)
        XCTAssertEqual(handler.pause_calledTimes, 0)
        XCTAssertEqual(handler.playerResumePlayback_Calls, [playbackTime])
        XCTAssertEqual(playbackUseCase.setPreference_Calls, [.resumePreviousSession])
    }
    
    func testAudioStartPlaying_resumeSession_resumesPlaybackAtTime() async {
        let exp = expectation(description: #function)
        let (sut, playbackUseCase, handler, _) = makeOnlineSUT()
        playbackUseCase._status = .resumeSession(playbackTime: playbackTime)
        handler.onPlayerResumePlaybackCompletion = { exp.fulfill() }
        await test(viewModel: sut, trigger: { sut.audioDidStartPlayingItem(testItem) }, expectedCommands: [], timeout: shortTimeout)
        await fulfillment(of: [exp], timeout: defaultTimeout)
        XCTAssertEqual(handler.playerResumePlayback_Calls, [playbackTime])
    }
    
    func testSelectPlaybackContinuationDialog_setsResumePreference() {
        let (sut, playbackUseCase, _, _) = makeOnlineSUT()
        sut.dispatch(.onSelectResumePlaybackContinuationDialog(playbackTime: playbackTime))
        XCTAssertEqual(playbackUseCase.setPreference_Calls, [.resumePreviousSession])
    }
    
    func testSelectRestartPlaybackContinuationDialog_setsRestartPreference() {
        let (sut, playbackUseCase, _, _) = makeOnlineSUT()
        sut.dispatch(.onSelectRestartPlaybackContinuationDialog)
        XCTAssertEqual(playbackUseCase.setPreference_Calls, [.restartFromBeginning])
    }
    
    func testViewWillDisappear_whenLoggedInAndDisappearReasonUserInitiatedDismissal_initMiniPlayer() async {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            accountUseCase: MockAccountUseCase(isLoggedIn: true)
        )
        await test(viewModel: sut, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 1)
    }
    
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonUserInitiatedDismissal_stopsPlayer() async {
        let handler = MockAudioPlayerHandler()
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: handler,
            accountUseCase: MockAccountUseCase(isLoggedIn: false)
        )
        await test(viewModel: sut, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
        XCTAssertEqual(handler.pause_calledTimes, 1)
        XCTAssertEqual(handler.closePlayer_calledTimes, 1)
    }
    
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonSystemPushedAnotherView_shouldNotStopsPlayer() {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            streamingInfoUseCase: MockStreamingInfoUseCase(),
            accountUseCase: MockAccountUseCase(isLoggedIn: false)
        )
        test(viewModel: sut, actions: [.viewWillDisappear(reason: .systemPushedAnotherView)], expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
    }
    
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsConnected_shouldInitMiniPlayer() async {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode, relatedFiles: ["File1"]),
            playerHandler: MockAudioPlayerHandler(),
            accountUseCase: MockAccountUseCase(isLoggedIn: true),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: true)
        )
        await test(viewModel: sut, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsDisconnected_shouldInitMiniPlayerWithoutStoppingAudio() async {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode, relatedFiles: ["File1"]),
            playerHandler: MockAudioPlayerHandler(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false)
        )
        await test(viewModel: sut, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [], timeout: shortTimeout)
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    func testAnalytics_onViewDidLoad_tracksIsActivated() {
        let tracker = MockTracker()
        let handler = MockAudioPlayerHandler()
        let mockNode = MockNode(handle: 1)
        let mockTrack = AudioPlayerItem(name: "", url: mockTrackURL, node: mockNode)
        handler.mockPlayerCurrentItem = mockTrack
        let config = audioPlayerConfigEntity(node: mockNode, allNodes: [mockNode])
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        streamingInfoUseCase.completeInfoNode(with: mockTrack)
        let (sut, _, _) = makeSUT(
            configEntity: config,
            playerHandler: handler,
            tracker: tracker,
            streamingInfoUseCase: streamingInfoUseCase
        )
        test(viewModel: sut, actions: [.onViewDidLoad], relaysCommand: .forceDisableMultiTrackControls, timeout: 10.0)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerIsActivatedEvent()])
    }
    
    func testAnalytics_onShuffleActive_tracksShuffleEnabled() async {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            tracker: tracker
        )
        await test(viewModel: sut, action: .onShuffle(active: true), expectedCommands: [.updateShuffle(status: true)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerShuffleEnabledEvent()])
    }
    
    func testAnalytics_onRepeatPressed_shouldTrackLoopAndRepeatOneEvents() async {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            tracker: tracker
        )
        await test(viewModel: sut, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .loop)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopQueueEnabledEvent()]
        )
        tracker.reset()
        await test(viewModel: sut, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .repeatOne)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopPlayingItemEnabledEvent()]
        )
        tracker.reset()
        await test(viewModel: sut, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testAnalytics_onChangeSpeed_sequence_tracksAll() async {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            tracker: tracker
        )
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .oneAndAHalf)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChangeOneAndHalfXEvent()])
        tracker.reset()
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .double)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChange2XEvent()])
        tracker.reset()
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .half)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChangeHalfXEvent()])
        tracker.reset()
        await test(viewModel: sut, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .normal)], timeout: shortTimeout)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChange1XEvent()])
        tracker.reset()
    }
    
    func testOnViewDidLoad_whenPlayerNotDefined_setsCurrentOnlyOnce() async {
        let handler = MockAudioPlayerHandler()
        handler.mockPlayerCurrentItem = AudioPlayerItem.mockItem
        let mockNode = MockNode(handle: 1)
        let config = audioPlayerConfigEntity(node: mockNode, allNodes: [mockNode])
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        streamingInfoUseCase.completeInfoNode(with: AudioPlayerItem.mockItem)
        let (sut, _, _) = makeSUT(
            configEntity: config,
            playerHandler: handler,
            streamingInfoUseCase: streamingInfoUseCase
        )
        let expected: [AudioPlayerViewModel.Command] = [
            .showLoading(true),
            .updateShuffle(status: handler.isShuffleEnabled()),
            .updateSpeed(mode: .normal),
            .enableUserInteraction(false, isSingleTrackPlayer: false),
            .configureDefaultPlayer,
            .forceDisableMultiTrackControls
        ]
        await test(viewModel: sut, action: .onViewDidLoad, expectedCommands: expected, timeout: shortTimeout)
        XCTAssertEqual(handler.addPlayer_calledTimes, 1)
        XCTAssertEqual(handler.addPlayerTracks_calledTimes, 1)
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 0)
    }
    
    func testOnViewDidLoad_existingPlayer_withStreamingNodes_addsListenerOnce() async {
        let handler = MockAudioPlayerHandler(isPlayerDefined: true)
        let mockNode = MockNode(handle: 1)
        let mockTrack = AudioPlayerItem(name: "", url: mockTrackURL, node: mockNode)
        handler.mockPlayerCurrentItem = mockTrack
        let config = audioPlayerConfigEntity(node: mockNode, allNodes: [mockNode])
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        streamingInfoUseCase.completeInfoNode(with: mockTrack)
        let (sut, _, _) = makeSUT(
            configEntity: config,
            playerHandler: handler,
            streamingInfoUseCase: streamingInfoUseCase
        )
        test(viewModel: sut, actions: [.onViewDidLoad], relaysCommand: .configureDefaultPlayer, timeout: shortTimeout)
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 1)
    }
    
    func testOnViewDidLoad_existingPlayer_withOfflineFiles_addsListenerOnce() {
        let handler = MockAudioPlayerHandler(isPlayerDefined: true)
        let mockNode = MockNode(handle: 1)
        let mockTrack = AudioPlayerItem(name: "", url: offlineURL, node: mockNode)
        handler.mockPlayerCurrentItem = mockTrack
        let config = AudioPlayerConfigEntity(fileLink: offlineFilePath, relatedFiles: ["path1"])
        let (sut, _, _) = makeSUT(configEntity: config, playerHandler: handler)
        
        test(viewModel: sut, actions: [.onViewDidLoad], relaysCommand: .configureOfflinePlayer, timeout: shortTimeout)
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 1)
    }
    
    private func makeOnlineSUT(isSingleItemPlaylist: Bool = false) -> (sut: AudioPlayerViewModel, playbackUseCase: MockPlaybackContinuationUseCase, playerHandler: MockAudioPlayerHandler, router: MockAudioPlayerViewRouter) {
        let playerHandler = MockAudioPlayerHandler(isSingleItemPlaylist: isSingleItemPlaylist)
        let config = AudioPlayerConfigEntity(node: MEGANode(), isFolderLink: false, fileLink: "")
        let (sut, playbackUseCase, router) = makeSUT(
            configEntity: config,
            playerHandler: playerHandler,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository(violatesTermsOfServiceResult: .success(false))),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository())
        )
        return (sut, playbackUseCase, playerHandler, router)
    }
    
    private func makeOfflineSUT() -> (sut: AudioPlayerViewModel, router: MockAudioPlayerViewRouter) {
        let playerHandler = MockAudioPlayerHandler()
        let (sut, _, router) = makeSUT(
            configEntity: AudioPlayerConfigEntity(fileLink: "file_path"),
            playerHandler: playerHandler,
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository())
        )
        return (sut, router)
    }
    
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        playerHandler: some AudioPlayerHandlerProtocol,
        tracker: some AnalyticsTracking = MockTracker(),
        nodeInfoUseCase: (some NodeInfoUseCaseProtocol)? = MockNodeInfoUseCase(),
        streamingInfoUseCase: (some StreamingInfoUseCaseProtocol)? = MockStreamingInfoUseCase(),
        offlineInfoUseCase: (some OfflineFileInfoUseCaseProtocol)? = OfflineFileInfoUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerViewModel, playbackContinuationUseCase: MockPlaybackContinuationUseCase, router: MockAudioPlayerViewRouter) {
        let playback = MockPlaybackContinuationUseCase()
        let router = MockAudioPlayerViewRouter()
        let sut = AudioPlayerViewModel(
            configEntity: configEntity,
            playerHandler: playerHandler,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: streamingInfoUseCase,
            offlineInfoUseCase: offlineInfoUseCase,
            playbackContinuationUseCase: playback,
            audioPlayerUseCase: MockAudioPlayerUseCase(),
            accountUseCase: accountUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            tracker: tracker
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, playback, router)
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: testItemName,
            url: anyURL,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
    
    private func audioPlayerConfigEntity(
        node: MockNode,
        isFolderLink: Bool = false,
        relatedFiles: [String]? = nil,
        fileLink: String? = nil,
        allNodes: [MEGANode]? = nil
    ) -> AudioPlayerConfigEntity {
        AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            relatedFiles: relatedFiles,
            allNodes: allNodes
        )
    }
}
