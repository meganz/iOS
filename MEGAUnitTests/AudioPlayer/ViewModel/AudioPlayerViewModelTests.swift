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
    let playbackTime: TimeInterval = 1234.0
    
    private func captureCommands(
        from viewModel: AudioPlayerViewModel,
        trigger: @MainActor () -> Void,
        timeout: TimeInterval = 0.3
    ) async -> [AudioPlayerViewModel.Command] {
        var buffer = [AudioPlayerViewModel.Command]()
        viewModel.invokeCommand = { buffer.append($0) }
        trigger()
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        return buffer
    }
    
    private func assertCommands(
        _ expected: [AudioPlayerViewModel.Command],
        when action: AudioPlayerAction,
        on viewModel: AudioPlayerViewModel,
        timeout: TimeInterval = 1.0,
        line: UInt = #line
    ) async {
        let cmds = await captureCommands(from: viewModel, trigger: { viewModel.dispatch(action) }, timeout: timeout)
        XCTAssertEqual(cmds, expected, line: line)
    }
    
    private func assertCommands(
        _ expected: [AudioPlayerViewModel.Command],
        trigger: @MainActor () -> Void,
        on viewModel: AudioPlayerViewModel,
        timeout: TimeInterval = 1.0,
        line: UInt = #line
    ) async {
        let cmds = await captureCommands(from: viewModel, trigger: trigger, timeout: timeout)
        XCTAssertEqual(cmds, expected, line: line)
    }
    
    private func tap(_ action: AudioPlayerAction, times: Int, on viewModel: AudioPlayerViewModel) {
        for _ in 0..<times { viewModel.dispatch(action) }
    }
    
    func testOnViewDidLoad_fileLinkPlayer_emitsExpectedCommands() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await assertCommands(
            [
                .showLoading(true),
                .updateShuffle(status: playerHandler.isShuffleEnabled()),
                .updateSpeed(mode: .normal),
                .enableUserInteraction(false, isSingleTrackPlayer: false),
                .configureFileLinkPlayer,
                .forceDisableMultiTrackControls
            ],
            when: .onViewDidLoad,
            on: onlineSUT
        )
    }
    
    func testUpdateCurrentTime_percentageGiven_progressCompletedCalled() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.updateCurrentTime(percentage: 0.2)) })
        XCTAssertEqual(playerHandler.updateProgressCompleted_calledTimes, 1)
    }
    
    func testOnShuffle_activeTrue_invokesPlayerShuffle() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        let enableShuffle = true
        await assertCommands([.updateShuffle(status: enableShuffle)], when: .onShuffle(active: enableShuffle), on: onlineSUT)
        XCTAssertEqual(playerHandler.onShuffle_calledTimes, 1)
    }
    
    func testOnPlayPause_action_invokesTogglePlay() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.onPlayPause) })
        XCTAssertEqual(playerHandler.togglePlay_calledTimes, 1)
    }
    
    func testOnGoBackward_action_invokesGoBackward() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.onGoBackward) })
        XCTAssertEqual(playerHandler.goBackward_calledTimes, 1)
    }
    
    func testOnPrevious_action_invokesPlayPrevious() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.onPrevious) })
        XCTAssertEqual(playerHandler.playPrevious_calledTimes, 1)
    }
    
    func testOnNext_action_invokesPlayNext() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.onNext) })
        XCTAssertEqual(playerHandler.playNext_calledTimes, 1)
    }
    
    func testOnGoForward_action_invokesGoForward() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.onGoForward) })
        XCTAssertEqual(playerHandler.goForward_calledTimes, 1)
    }
    
    func testOnRepeatPressed_firstPress_updatesRepeatOne() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await assertCommands([.updateRepeat(status: .repeatOne)], when: .onRepeatPressed, on: onlineSUT)
        XCTAssertEqual(playerHandler.onRepeatOne_calledTimes, 1)
    }
    
    func testOnRepeatPressed_secondPress_updatesRepeatNone() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onRepeatPressed)
        await assertCommands([.updateRepeat(status: .none)], when: .onRepeatPressed, on: onlineSUT)
        XCTAssertEqual(playerHandler.onRepeatDisabled_calledTimes, 1)
    }
    
    func testOnRepeatPressed_singleItemPlaylist_cyclesBetweenNoneAndRepeatOne() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT(isSingleItemPlaylist: true)
        onlineSUT.dispatch(.onRepeatPressed)
        await assertCommands([.updateRepeat(status: .none)], when: .onRepeatPressed, on: onlineSUT)
        XCTAssertTrue(playerHandler.isSingleItemPlaylist())
        await assertCommands([.updateRepeat(status: .repeatOne)], when: .onRepeatPressed, on: onlineSUT)
        await assertCommands([.updateRepeat(status: .none)], when: .onRepeatPressed, on: onlineSUT)
    }
    
    func testRemoveDelegates_action_invokesRemovePlayerListener() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.removeDelegates) })
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
    }
    
    func testOnChangeSpeedModePressed_firstPress_updatesOneAndAHalfX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        await assertCommands([.updateSpeed(mode: .oneAndAHalf)], when: .onChangeSpeedModePressed, on: onlineSUT)
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 1)
    }
    
    func testOnChangeSpeedModePressed_secondPress_updatesDoubleX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onChangeSpeedModePressed)
        await assertCommands([.updateSpeed(mode: .double)], when: .onChangeSpeedModePressed, on: onlineSUT)
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 2)
    }
    
    func testOnChangeSpeedModePressed_thirdPress_updatesHalfX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        tap(.onChangeSpeedModePressed, times: 2, on: onlineSUT)
        await assertCommands([.updateSpeed(mode: .half)], when: .onChangeSpeedModePressed, on: onlineSUT)
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 3)
    }
    
    func testOnChangeSpeedModePressed_fourthPress_updatesNormalX() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        tap(.onChangeSpeedModePressed, times: 3, on: onlineSUT)
        await assertCommands([.updateSpeed(mode: .normal)], when: .onChangeSpeedModePressed, on: onlineSUT)
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 4)
    }
    
    func testRouterActions() async {
        let (onlineSUT, _, _, onlineRouter) = makeOnlineSUT()
        let (offlineSUT, offlineRouter) = makeOfflineSUT()
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.dismiss) })
        XCTAssertEqual(onlineRouter.dismiss_calledTimes, 1)
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.showPlaylist) })
        XCTAssertEqual(onlineRouter.goToPlaylist_calledTimes, 1)
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal)) })
        XCTAssertEqual(onlineRouter.showMiniPlayer_calledTimes, 1)
        
        _ = await captureCommands(from: offlineSUT, trigger: { offlineSUT.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal)) })
        XCTAssertEqual(offlineRouter.showMiniPlayer_calledTimes, 1)
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.initMiniPlayer) })
        XCTAssertEqual(onlineRouter.showMiniPlayer_calledTimes, 2)
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.import) })
        XCTAssertEqual(onlineRouter.importNode_calledTimes, 1)
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.share(sender: nil)) })
        XCTAssertEqual(onlineRouter.share_calledTimes, 1)
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.sendToChat) })
        XCTAssertEqual(onlineRouter.sendToContact_calledTimes, 1)
        
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.dispatch(.showActionsforCurrentNode(sender: UIButton())) })
        XCTAssertEqual(onlineRouter.showAction_calledTimes, 1)
    }
    
    func testOnReceiveAudioPlayerActions_shouldInvokeCorrectCommands() async {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        playbackUseCase._status = .startFromBeginning
        await assertCommands([], trigger: { onlineSUT.audioDidStartPlayingItem(testItem) }, on: onlineSUT)
    }
    
    func testAudioStartPlayingWithDisplayDialogStatus_shouldDisplayDialog_andPausePlayer_whenAppIsActive() async {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { true }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        let expected: [AudioPlayerViewModel.Command] = [
            .displayPlaybackContinuationDialog(fileName: testItem.name, playbackTime: playbackTime)
        ]
        await assertCommands(expected, trigger: { onlineSUT.audioDidStartPlayingItem(testItem) }, on: onlineSUT)
        XCTAssertEqual(playerHandler.pause_calledTimes, 1)
    }
    
    func testAudioStartPlayingWithDisplayDialogStatus_shouldNotDisplayDialog_whenAppIsNotActive() async {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        await assertCommands([], trigger: { onlineSUT.audioDidStartPlayingItem(testItem) }, on: onlineSUT)
    }
    
    func testAudioStartPlayingWithDisplayDialogStatus_shouldResumePlayback_whenAppIsNotActive() async {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: playbackTime)
        let exp = expectation(description: #function)
        playerHandler.onPlayerResumePlaybackCompletion = { exp.fulfill() }
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.audioDidStartPlayingItem(testItem) })
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(playerHandler.pause_calledTimes, 0)
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [playbackTime])
        XCTAssertEqual(playbackUseCase.setPreference_Calls, [.resumePreviousSession])
    }
    
    func testAudioPlaybackContinuation_resumeSession() async {
        let exp = expectation(description: #function)
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        playbackUseCase._status = .resumeSession(playbackTime: playbackTime)
        playerHandler.onPlayerResumePlaybackCompletion = { exp.fulfill() }
        _ = await captureCommands(from: onlineSUT, trigger: { onlineSUT.audioDidStartPlayingItem(testItem) })
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [playbackTime])
    }
    
    func testSelectPlaybackContinuationDialog_shouldSetPreference() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onSelectResumePlaybackContinuationDialog(playbackTime: playbackTime))
        XCTAssertEqual(playbackUseCase.setPreference_Calls, [.resumePreviousSession])
        onlineSUT.dispatch(.onSelectRestartPlaybackContinuationDialog)
        XCTAssertEqual(playbackUseCase.setPreference_Calls, [.resumePreviousSession, .restartFromBeginning])
    }
    
    func testViewWillDisappear_whenLoggedInAndDisappearReasonUserInitiatedDismissal_initMiniPlayer() async {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            accountUseCase: MockAccountUseCase(isLoggedIn: true)
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal)) })
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 1)
    }
    
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonUserInitiatedDismissal_stopsPlayer() async {
        let handler = MockAudioPlayerHandler()
        let defaultConfig = audioPlayerConfigEntity(node: anyAudioNode)
        let (sut, _, router) = makeSUT(
            configEntity: defaultConfig,
            playerHandler: handler,
            streamingInfoUseCase: MockStreamingInfoUseCase(),
            accountUseCase: MockAccountUseCase(isLoggedIn: false)
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onViewDidLoad) })
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal)) })
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
        XCTAssertEqual(handler.pause_calledTimes, 1)
        XCTAssertEqual(handler.closePlayer_calledTimes, 1)
    }
    
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonSystemPushedAnotherView_shouldNotStopsPlayer() async {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            streamingInfoUseCase: MockStreamingInfoUseCase(),
            accountUseCase: MockAccountUseCase(isLoggedIn: false)
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onViewDidLoad) })
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.viewWillDisappear(reason: .systemPushedAnotherView)) })
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
    }
    
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsConnected_shouldInitMiniPlayer() async {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode, relatedFiles: ["File1"]),
            playerHandler: MockAudioPlayerHandler(),
            accountUseCase: MockAccountUseCase(isLoggedIn: true),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: true)
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal)) })
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsDisconnected_shouldInitMiniPlayerWithoutStoppingAudio() async {
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode, relatedFiles: ["File1"]),
            playerHandler: MockAudioPlayerHandler(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false)
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal)) })
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    func testAnalytics_onViewDidLoad_shouldTrackAudioPlayerIsActivatedEvent() async {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            tracker: tracker
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onViewDidLoad) })
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerIsActivatedEvent()]
        )
    }
    
    func testAnalytics_onShuffleActive_shouldTrackAudioPlayerShuffleEnabledEvent() async {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            tracker: tracker
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onShuffle(active: true)) })
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerShuffleEnabledEvent()]
        )
    }
    
    func testAnalytics_onRepeatPressed_shouldTrackLoopAndRepeatOneEvents() async {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            tracker: tracker
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onRepeatPressed) })
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopQueueEnabledEvent()]
        )
        tracker.reset()
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onRepeatPressed) })
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopPlayingItemEnabledEvent()]
        )
        tracker.reset()
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onRepeatPressed) })
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testAnalytics_onChangeSpeedModePressed_shouldTrackSpeedChangeEvents() async {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            playerHandler: MockAudioPlayerHandler(),
            tracker: tracker
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onChangeSpeedModePressed) })
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChangeOneAndHalfXEvent()])
        tracker.reset()
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onChangeSpeedModePressed) })
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChange2XEvent()])
        tracker.reset()
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onChangeSpeedModePressed) })
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChangeHalfXEvent()])
        tracker.reset()
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onChangeSpeedModePressed) })
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerSpeedChange1XEvent()])
    }
    
    func testDispatchOnViewDidLoad_whenPlayerNotDefined_shouldCallSetCurrentOnlyOnce() async {
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
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onViewDidLoad) })
        XCTAssertEqual(handler.addPlayer_calledTimes, 1)
        XCTAssertEqual(handler.addPlayerTracks_calledTimes, 1)
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 0)
    }
    
    func testDispatchOnViewDidLoad_existingPlayerWithStreamingNodes_shouldCallAddsListenerOnce() async {
        let handler = MockAudioPlayerHandler(isPlayerDefined: true)
        let mockNode = MockNode(handle: 1)
        let mockTrack = AudioPlayerItem(name: "", url: URL(string: "www.url.com")!, node: mockNode)
        handler.mockPlayerCurrentItem = mockTrack
        let config = audioPlayerConfigEntity(node: mockNode, allNodes: [mockNode])
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        streamingInfoUseCase.completeInfoNode(with: mockTrack)
        let (sut, _, _) = makeSUT(
            configEntity: config,
            playerHandler: handler,
            streamingInfoUseCase: streamingInfoUseCase
        )
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onViewDidLoad) })
        XCTAssertEqual(handler.addPlayerListener_calledTimes, 1)
    }
    
    func testDispatchOnViewDidLoad_existingPlayerWithOfflineFiles_shouldCallAddsListenerOnce() async {
        let handler = MockAudioPlayerHandler(isPlayerDefined: true)
        let mockNode = MockNode(handle: 1)
        let mockTrack = AudioPlayerItem(name: "", url: URL(string: "offline_file")!, node: mockNode)
        handler.mockPlayerCurrentItem = mockTrack
        let config = AudioPlayerConfigEntity(fileLink: "offline_file", relatedFiles: ["path1"])
        let (sut, _, _) = makeSUT(configEntity: config, playerHandler: handler)
        _ = await captureCommands(from: sut, trigger: { sut.dispatch(.onViewDidLoad) })
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
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)
        return (sut, playback, router)
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
        XCTAssertTrue(player.observerSnapshot().isEmpty, file: file, line: line)
        XCTAssertTrue(player.observerSnapshot().notContains(where: { $0 as! AnyHashable == sut as! AnyHashable }), file: file, line: line)
    }
    
    private var anyAudioNode: MockNode {
        MockNode(handle: 1, name: "first-audio.mp3", nodeType: .file)
    }
}
