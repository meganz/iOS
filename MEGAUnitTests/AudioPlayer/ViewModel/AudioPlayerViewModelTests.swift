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

final class AudioPlayerViewModelTests: XCTestCase {
    let playbackTime: TimeInterval = 1234.0
    
    @MainActor
    func testOnViewDidLoad_fileLinkPlayer_emitsExpectedCommands() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        
        await test(
            viewModel: onlineSUT,
            action: .onViewDidLoad,
            expectedCommands: [
                .showLoading(true),
                .updateShuffle(status: playerHandler.isShuffleEnabled()),
                .updateSpeed(mode: .normal),
                .configureFileLinkPlayer
            ],
            timeout: 0.5
        )
    }
    
    @MainActor
    func testUpdateCurrentTime_percentageGiven_progressCompletedCalled() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .updateCurrentTime(percentage: 0.2),
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.updateProgressCompleted_calledTimes, 1)
    }
    
    @MainActor
    func testOnShuffle_activeTrue_invokesPlayerShuffle() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        let enableShuffle = true
        await test(
            viewModel: onlineSUT,
            action: .onShuffle(active: enableShuffle),
            expectedCommands: [.updateShuffle(status: enableShuffle)]
        )
        XCTAssertEqual(playerHandler.onShuffle_calledTimes, 1)
    }
    
    @MainActor
    func testOnPlayPause_action_invokesTogglePlay() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .onPlayPause,
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.togglePlay_calledTimes, 1)
    }
    
    @MainActor
    func testOnGoBackward_action_invokesGoBackward() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .onGoBackward,
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.goBackward_calledTimes, 1)
    }
    
    @MainActor
    func testOnPrevious_action_invokesPlayPrevious() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .onPrevious,
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.playPrevious_calledTimes, 1)
    }
    
    @MainActor
    func testOnNext_action_invokesPlayNext() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .onNext,
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.playNext_calledTimes, 1)
    }
    
    @MainActor
    func testOnGoForward_action_invokesGoForward() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .onGoForward,
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.goForward_calledTimes, 1)
    }
    
    @MainActor
    func testOnRepeatPressed_firstPress_updatesRepeatOne() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .onRepeatPressed,
            expectedCommands: [.updateRepeat(status: .repeatOne)]
        )
        XCTAssertEqual(playerHandler.onRepeatOne_calledTimes, 1)
    }
    
    @MainActor
    func testOnRepeatPressed_secondPress_updatesRepeatNone() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onRepeatPressed)
        await test(
            viewModel: onlineSUT,
            action: .onRepeatPressed,
            expectedCommands: [.updateRepeat(status: .none)]
        )
        XCTAssertEqual(playerHandler.onRepeatDisabled_calledTimes, 1)
    }
    
    @MainActor
    func testOnRepeatPressed_singleItemPlaylist_cyclesBetweenNoneAndRepeatOne() async throws {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT(isSingleItemPlaylist: true)
        onlineSUT.dispatch(.onRepeatPressed)
        await test(
            viewModel: onlineSUT,
            action: .onRepeatPressed,
            expectedCommands: [.updateRepeat(status: .none)]
        )
        XCTAssertTrue(playerHandler.isSingleItemPlaylist())
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await test(
            viewModel: onlineSUT,
            action: .onRepeatPressed,
            expectedCommands: [.updateRepeat(status: .repeatOne)]
        )
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await test(
            viewModel: onlineSUT,
            action: .onRepeatPressed,
            expectedCommands: [.updateRepeat(status: .none)]
        )
    }
    
    @MainActor
    func testRemoveDelegates_action_invokesRemovePlayerListener() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .removeDelegates,
            expectedCommands: []
        )
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
    }
    
    @MainActor
    func testOnChangeSpeedModePressed_firstPress_updatesOneAndAHalfX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await test(
            viewModel: onlineSUT,
            action: .onChangeSpeedModePressed,
            expectedCommands: [.updateSpeed(mode: .oneAndAHalf)]
        )
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 1)
    }
    
    @MainActor
    func testOnChangeSpeedModePressed_secondPress_updatesDoubleX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onChangeSpeedModePressed)
        await test(
            viewModel: onlineSUT,
            action: .onChangeSpeedModePressed,
            expectedCommands: [.updateSpeed(mode: .double)]
        )
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 2)
    }
    
    @MainActor
    func testOnChangeSpeedModePressed_thirdPress_updatesHalfX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onChangeSpeedModePressed)
        onlineSUT.dispatch(.onChangeSpeedModePressed)
        await test(
            viewModel: onlineSUT,
            action: .onChangeSpeedModePressed,
            expectedCommands: [.updateSpeed(mode: .half)]
        )
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 3)
    }
    
    @MainActor
    func testOnChangeSpeedModePressed_fourthPress_updatesNormalX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onChangeSpeedModePressed)
        onlineSUT.dispatch(.onChangeSpeedModePressed)
        onlineSUT.dispatch(.onChangeSpeedModePressed)
        await test(
            viewModel: onlineSUT,
            action: .onChangeSpeedModePressed,
            expectedCommands: [.updateSpeed(mode: .normal)]
        )
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 4)
    }
    
    @MainActor
    func testRouterActions() async {
        let (onlineSUT, _, _, onlineRouter) = makeOnlineSUT()
        let (offlineSUT, offlineRouter) = makeOfflineSUT()
        
        await test(viewModel: onlineSUT, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(onlineRouter.dismiss_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .showPlaylist, expectedCommands: [])
        XCTAssertEqual(onlineRouter.goToPlaylist_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [])
        XCTAssertEqual(onlineRouter.showMiniPlayer_calledTimes, 1)
        
        await test(viewModel: offlineSUT, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [])
        XCTAssertEqual(offlineRouter.showMiniPlayer_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(onlineRouter.showMiniPlayer_calledTimes, 2)
        
        await test(viewModel: onlineSUT, action: .`import`, expectedCommands: [])
        XCTAssertEqual(onlineRouter.importNode_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .share(sender: nil), expectedCommands: [])
        XCTAssertEqual(onlineRouter.share_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .sendToChat, expectedCommands: [])
        XCTAssertEqual(onlineRouter.sendToContact_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .showActionsforCurrentNode(sender: UIButton()), expectedCommands: [])
        XCTAssertEqual(onlineRouter.showAction_calledTimes, 1)
    }
    
    @MainActor
    func testOnReceiveAudioPlayerActions_shouldInvokeCorrectCommands() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        playbackUseCase._status = .startFromBeginning
        
        assert(
            onlineSUT,
            when: { viewModel in
                viewModel.audioDidStartPlayingItem(testItem)
            },
            shouldInvokeCommands: []
        )
    }
    
    @MainActor
    func testAudioStartPlayingWithDisplayDialogStatus_shouldDisplayDialog_andPausePlayer_whenAppIsActive() async {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { true }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        
        let expectedCommands: [AudioPlayerViewModel.Command] = [
            .displayPlaybackContinuationDialog(
                fileName: testItem.name,
                playbackTime: playbackTime
            )
        ]
        
        await test(
            viewModel: onlineSUT,
            trigger: { onlineSUT.audioDidStartPlayingItem(testItem) },
            expectedCommands: expectedCommands
        )
        
        XCTAssertEqual(playerHandler.pause_calledTimes, 1)
    }
    
    @MainActor
    func testAudioStartPlayingWithDisplayDialogStatus_shouldNotDisplayDialog_whenAppIsNotActive() async {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        
        await test(
            viewModel: onlineSUT,
            trigger: { onlineSUT.audioDidStartPlayingItem(testItem) },
            expectedCommands: []
        )
    }
    
    @MainActor
    func testAudioStartPlayingWithDisplayDialogStatus_shouldResumePlayback_whenAppIsNotActive() {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        
        let expectation = XCTestExpectation(description: #function)
        
        playerHandler.onPlayerResumePlaybackCompletion = {
            expectation.fulfill()
        }
        
        onlineSUT.audioDidStartPlayingItem(testItem)
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(playerHandler.pause_calledTimes, 0)
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [playbackTime])
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession]
        )
    }
    
    @MainActor
    func testAudioPlaybackContinuation_resumeSession() async {
        let expectation = expectation(description: #function)
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        playbackUseCase._status = .resumeSession(playbackTime: playbackTime)
        
        playerHandler.onPlayerResumePlaybackCompletion = {
            expectation.fulfill()
        }
        
        onlineSUT.audioDidStartPlayingItem(testItem)
        
        await fulfillment(of: [expectation], timeout: 1)
        
        XCTAssertEqual(
            playerHandler.playerResumePlayback_Calls,
            [playbackTime]
        )
    }
    
    @MainActor
    func testSelectPlaybackContinuationDialog_shouldSetPreference() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onSelectResumePlaybackContinuationDialog(playbackTime: playbackTime))
        
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession]
        )
        
        onlineSUT.dispatch(.onSelectRestartPlaybackContinuationDialog)
        
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession, .restartFromBeginning]
        )
    }
    
    // MARK: - viewWillDisappear
    
    @MainActor
    func testViewWillDisappear_whenLoggedInAndDisappearReasonUserInitiatedDismissal_initMiniPlayer() {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            accountUseCase: MockAccountUseCase(isLoggedIn: true)
        )
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 1)
    }
    
    @MainActor
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonUserInitiatedDismissal_stopsPlayer() {
        let playerHandler = MockAudioPlayerHandler()
        let playerHandlerBuilder = MockAudioPlayerHandlerBuilder(handler: playerHandler)
        let defaultConfigEntity = audioPlayerConfigEntity(node: anyAudioNode, playerHandlerBuilder: playerHandlerBuilder)
        let (sut, _, router) = makeSUT(
            configEntity: defaultConfigEntity,
            streamingInfoUseCase: MockStreamingInfoUseCase(),
            accountUseCase: MockAccountUseCase(isLoggedIn: false)
        )
        sut.dispatch(.onViewDidLoad)
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
        XCTAssertEqual(playerHandler.pause_calledTimes, 1)
        XCTAssertEqual(playerHandler.closePlayer_calledTimes, 1)
    }
    
    @MainActor
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonSystemPushedAnotherView_shouldNotStopsPlayer() {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            streamingInfoUseCase: MockStreamingInfoUseCase(),
            accountUseCase: MockAccountUseCase(isLoggedIn: false)
        )
        sut.dispatch(.onViewDidLoad)
        
        sut.dispatch(.viewWillDisappear(reason: .systemPushedAnotherView))
        
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
    }
    
    // MARK: - Analytics
    
    @MainActor
    func testAnalytics_onViewDidLoad_shouldTrackAudioPlayerIsActivatedEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onViewDidLoad)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerIsActivatedEvent()])
    }
    
    @MainActor
    func testAnalytics_onShuffleActive_shouldTrackAudioPlayerShuffleEnabledEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onShuffle(active: true))
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerShuffleEnabledEvent()])
    }
    
    @MainActor
    func testAnalytics_onRepeatPressed_shouldTrackLoopAndRepeatOneEvents() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onRepeatPressed)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopQueueEnabledEvent()])
        
        tracker.reset()
        
        sut.dispatch(.onRepeatPressed)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopPlayingItemEnabledEvent()])
        
        tracker.reset()
        
        sut.dispatch(.onRepeatPressed)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [])
    }
    
    @MainActor
    func testAnalytics_showPlaylist_shouldTrackQueueButtonPressedEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.showPlaylist)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueButtonPressedEvent()])
    }
    
    @MainActor
    func testAnalytics_onChangeSpeedModePressed_shouldTrackSpeedChangeEvents() {
        let tracker = MockTracker()
        
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChangeOneAndHalfXEvent()]
        )
        
        tracker.reset()
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChange2XEvent()]
        )
        
        tracker.reset()
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChangeHalfXEvent()]
        )
        
        tracker.reset()
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChange1XEvent()]
        )
    }
    
    @MainActor
    func testAnalytics_onGoBackward_shouldTrackBackwardEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        sut.dispatch(.onGoBackward)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerBack15SecondsEvent()]
        )
    }
    
    @MainActor
    func testAnalytics_onGoForward_shouldTrackForwardEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        sut.dispatch(.onGoForward)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerForward15SecondsEvent()]
        )
    }
    
    @MainActor
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsConnected_shouldInitMiniPlayer() {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(
                node: anyAudioNode,
                relatedFiles: ["File1"]
            ),
            accountUseCase: MockAccountUseCase(isLoggedIn: true),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: true)
        )
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    @MainActor
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsDisconnected_shouldInitMiniPlayerWithoutStoppingAudio() {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(
                node: anyAudioNode,
                relatedFiles: ["File1"]
            ),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false)
        )
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    @MainActor
    func testDispatchOnViewDidLoad_whenPlayerNotDefined_shouldCallSetCurrentOnlyOnce() async throws {
        let handler = MockAudioPlayerHandler()
        handler.mockPlayerCurrentItem = AudioPlayerItem.mockItem
        let mockNode = MockNode(handle: 1)
        let config  = audioPlayerConfigEntity(
            node: mockNode,
            allNodes: [mockNode],
            playerHandlerBuilder: MockAudioPlayerHandlerBuilder(handler: handler)
        )
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        streamingInfoUseCase.completeInfoNode(with: AudioPlayerItem.mockItem)
        let (sut, _, _) = makeSUT(
            configEntity: config,
            streamingInfoUseCase: streamingInfoUseCase
        )
        
        sut.dispatch(.onViewDidLoad)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(handler.addPlayer_calledTimes, 1)
        XCTAssertEqual(handler.addPlayerTracks_calledTimes, 1)
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 0)
    }
    
    @MainActor
    func testDispatchOnViewDidLoad_existingPlayerWithStreamingNodes_shouldCallAddsListenerOnce() async throws {
        let handler = MockAudioPlayerHandler(isPlayerDefined: true)
        let mockNode = MockNode(handle: 1)
        let mockTrack = AudioPlayerItem(name: "", url: URL(string: "www.url.com")!, node: mockNode)
        handler.mockPlayerCurrentItem = mockTrack
        let config  = audioPlayerConfigEntity(
            node: mockNode,
            allNodes: [mockNode],
            playerHandlerBuilder: MockAudioPlayerHandlerBuilder(handler: handler)
        )
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        streamingInfoUseCase.completeInfoNode(with: mockTrack)
        let (sut, _, _) = makeSUT(
            configEntity: config,
            streamingInfoUseCase: streamingInfoUseCase
        )
        
        sut.dispatch(.onViewDidLoad)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 1)
    }
    
    @MainActor
    func testDispatchOnViewDidLoad_existingPlayerWithOfflineFiles_shouldCallAddsListenerOnce() async throws {
        let handler = MockAudioPlayerHandler(isPlayerDefined: true)
        let mockNode = MockNode(handle: 1)
        let mockTrack = AudioPlayerItem(name: "", url: URL(string: "offline_file")!, node: mockNode)
        handler.mockPlayerCurrentItem = mockTrack
        let config = AudioPlayerConfigEntity(
            fileLink: "offline_file",
            relatedFiles: ["path1"],
            audioPlayerHandlerBuilder: MockAudioPlayerHandlerBuilder(handler: handler)
        )
        let (sut, _, _) = makeSUT(configEntity: config)
        
        sut.dispatch(.onViewDidLoad)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 1)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeOnlineSUT(isSingleItemPlaylist: Bool = false) -> (sut: AudioPlayerViewModel, playbackUseCase: MockPlaybackContinuationUseCase, playerHandler: MockAudioPlayerHandler, router: MockAudioPlayerViewRouter) {
        let playerHandler = MockAudioPlayerHandler(isSingleItemPlaylist: isSingleItemPlaylist)
        let builder = MockAudioPlayerHandlerBuilder(handler: playerHandler)
        let config = AudioPlayerConfigEntity(
            node: MEGANode(),
            isFolderLink: false,
            fileLink: "",
            audioPlayerHandlerBuilder: builder
        )
        let (sut, playbackUseCase, router) = makeSUT(
            configEntity: config,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository(violatesTermsOfServiceResult: .success(false))),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository())
        )
        return (sut, playbackUseCase, playerHandler, router)
    }
    
    @MainActor
    private func makeOfflineSUT() -> (sut: AudioPlayerViewModel, router: MockAudioPlayerViewRouter) {
        let (sut, _, router) = makeSUT(
            configEntity: AudioPlayerConfigEntity(fileLink: "file_path"),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository())
        )
        return (sut, router)
    }
    
    @MainActor
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        tracker: some AnalyticsTracking = MockTracker(),
        nodeInfoUseCase: (some NodeInfoUseCaseProtocol)? = MockNodeInfoUseCase(),
        streamingInfoUseCase: (some StreamingInfoUseCaseProtocol)? = MockStreamingInfoUseCase(),
        offlineInfoUseCase: (some OfflineFileInfoUseCaseProtocol)? = OfflineFileInfoUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerViewModel, playbackContinuationUseCase: MockPlaybackContinuationUseCase, router: MockAudioPlayerViewRouter) {
        let mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
        let router = MockAudioPlayerViewRouter()
        
        let sut = AudioPlayerViewModel(
            configEntity: configEntity,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: streamingInfoUseCase,
            offlineInfoUseCase: offlineInfoUseCase,
            playbackContinuationUseCase: mockPlaybackContinuationUseCase,
            audioPlayerUseCase: MockAudioPlayerUseCase(),
            accountUseCase: accountUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            tracker: tracker
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)
        return (sut, mockPlaybackContinuationUseCase, router)
    }
    
    @MainActor
    private func simulateUserViewDidLoadWithNewInstane(audioNode: MockNode) -> (sut: AudioPlayerViewModel, playbackUseCase: MockPlaybackContinuationUseCase, playerHandler: MockAudioPlayerHandler, router: MockAudioPlayerViewRouter) {
        let configEntity = audioPlayerConfigEntity(node: audioNode)
        let (sut, playbackUseCase, router) = makeSUT(
            configEntity: configEntity,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository(violatesTermsOfServiceResult: .success(false))),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository())
        )
        sut.dispatch(.onViewDidLoad)
        return (sut, playbackUseCase, configEntity.playerHandler as! MockAudioPlayerHandler, router)
    }
    
    @MainActor
    private func assert(
        _ viewModel: AudioPlayerViewModel,
        when action: (AudioPlayerViewModel) -> Void,
        shouldInvokeCommands expectedCommands: [AudioPlayerViewModel.Command],
        line: UInt = #line
    ) {
        var invokedCommands =  [AudioPlayerViewModel.Command]()
        viewModel.invokeCommand = { invokedCommands.append($0) }
        
        action(viewModel)
        
        XCTAssertEqual(invokedCommands, expectedCommands, line: line)
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: "test-name",
            url: URL(string: "any-url")!,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
    
    private func audioPlayerConfigEntity(
        node: MockNode,
        isFolderLink: Bool = false,
        relatedFiles: [String]? = nil,
        fileLink: String? = nil,
        allNodes: [MEGANode]? = nil,
        playerHandlerBuilder: some AudioPlayerHandlerBuilderProtocol = MockAudioPlayerHandlerBuilder()
    ) -> AudioPlayerConfigEntity {
        AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            relatedFiles: relatedFiles,
            allNodes: allNodes,
            audioPlayerHandlerBuilder: playerHandlerBuilder
        )
    }
    
    private func assertThatCleanPlayerStateForReuse(on playerHandler: MockAudioPlayerHandler, sut: AudioPlayerViewModel, file: StaticString = #filePath, line: UInt = #line) throws {
        let player = try XCTUnwrap(playerHandler.currentPlayer(), file: file, line: line)
        assertThatRemovePreviousQueuedTrackInPlayer(on: player, file: file, line: line)
        assertThatRefreshPlayerListener(on: player, sut: sut, file: file, line: line)
    }
    
    private func assertThatRemovePreviousQueuedTrackInPlayer(on player: AudioPlayer, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(player.queuePlayer, file: file, line: line)
        XCTAssertTrue(player.tracks.isEmpty, file: file, line: line)
    }
    
    private func assertThatRefreshPlayerListener(on player: AudioPlayer, sut: AudioPlayerViewModel, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(player.observersListenerManager.listeners.isEmpty, file: file, line: line)
        XCTAssertTrue(player.observersListenerManager.listeners.notContains(where: { $0 as! AnyHashable == sut as! AnyHashable }), file: file, line: line)
    }
    
    private var anyAudioNode: MockNode {
        MockNode(handle: 1, name: "first-audio.mp3", nodeType: .file)
    }
}
