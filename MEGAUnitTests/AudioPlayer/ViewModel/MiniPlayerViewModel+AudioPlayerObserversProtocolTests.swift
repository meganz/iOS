@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class MiniPlayerViewModel_AudioPlayerObserversProtocolTests: XCTestCase {
    private let defaultTimeout: TimeInterval = 0.05
    
    private func captureCommands(
        from viewModel: MiniPlayerViewModel,
        trigger: @MainActor () -> Void,
        timeout: TimeInterval = 0.05
    ) async -> [MiniPlayerViewModel.Command] {
        var buffer = [MiniPlayerViewModel.Command]()
        viewModel.invokeCommand = { buffer.append($0) }
        trigger()
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        return buffer
    }
    
    private func assertCommands(
        _ expected: [MiniPlayerViewModel.Command],
        trigger: @MainActor () -> Void,
        on viewModel: MiniPlayerViewModel,
        timeout: TimeInterval = 0.05,
        line: UInt = #line
    ) async {
        let cmds = await captureCommands(from: viewModel, trigger: trigger, timeout: timeout)
        XCTAssertEqual(cmds, expected, line: line)
    }
    
    // MARK: - audioPlayerShowLoading
    
    func testAudioPlayerShowLoading_whenCalled_showsLoading() async {
        let (sut, _, _) = makeSUT()
        await assertCommands(
            [.showLoading(true)],
            trigger: { sut.audio(player: anyQueuePlayer(), showLoading: true)
            },
            on: sut,
            timeout: defaultTimeout)
    }
    
    func testAudioPlayerShowLoading_whenCalled_HidesLoading() async {
        let (sut, _, _) = makeSUT()
        await assertCommands(
            [.showLoading(false)],
            trigger: { sut.audio(player: anyQueuePlayer(), showLoading: false)
            },
            on: sut,
            timeout: defaultTimeout)
    }
    
    // MARK: - audioPlayerCurrentTime
    
    func testAudioPlayerCurrentTime_whenCalled_reloadsPlayerStatus() async {
        let (sut, _, _) = makeSUT()
        await assertCommands(
            [.reloadPlayerStatus(percentage: 40, isPlaying: true)],
            trigger: { sut.audio(player: anyQueuePlayer(), currentTime: 0, remainingTime: 0, percentageCompleted: 40, isPlaying: true)
            },
            on: sut,
            timeout: defaultTimeout)
    }
    
    // MARK: - audioPlayerCurrentItemIndexPath
    
    func testAudioPlayerCurrentItemIndexPath_whenNils_doesNotChangeCurrentItemAtIndexPath() {
        let (sut, _, _) = makeSUT()
        var received = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { received.append($0) }
        sut.audio(player: anyQueuePlayer(), currentItem: nil, indexPath: nil)
        XCTAssertTrue(received.isEmpty)
    }
    
    func testAudioPlayerCurrentItemIndexPath_whenCalled_changesCurrentItemAtIndexPath() async {
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let indexPath = anyIndexPath()
        let (sut, _, _) = makeSUT()
        await assertCommands(
            [.change(currentItem: item, indexPath: indexPath)],
            trigger: { sut.audio(player: anyQueuePlayer(), currentItem: item, indexPath: indexPath)
            },
            on: sut,
            timeout: defaultTimeout)
    }
    
    // MARK: - audioPlayerReloadItemIndexPath
    
    func testAudioPlayerReloadItemIndexPath_whenItemIsNil_doesNotReloadItem() {
        let (sut, _, _) = makeSUT()
        var received = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { received.append($0) }
        sut.audio(player: anyQueuePlayer(), reload: nil)
        XCTAssertTrue(received.isEmpty)
    }
    
    func testAudioPlayerReloadItem_whenHasItem_reloadsItem() async {
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, _, _) = makeSUT()
        await assertCommands(
            [.reload(item: item)],
            trigger: { sut.audio(player: anyQueuePlayer(), reload: item)
            },
            on: sut,
            timeout: defaultTimeout)
    }
    
    // MARK: - audioPlayerWillStartBlockingAction
    
    func testAudioPlayerWillStartBlockingAction_whenCalled_disableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        await assertCommands(
            [.enableUserInteraction(false)],
            trigger: { sut.audioPlayerWillStartBlockingAction()
            },
            on: sut,
            timeout: defaultTimeout)
    }
    
    // MARK: - audioPlayerDidFinishBlockingAction
    
    func testAudioPlayerDidFinishBlockingAction_whenCalled_enableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        await assertCommands(
            [.enableUserInteraction(true)],
            trigger: { sut.audioPlayerDidFinishBlockingAction()
            },
            on: sut,
            timeout: defaultTimeout)
    }
    
    // MARK: - audioDidStartPlayingItem
    
    func testAudioDidStartPlayingItem_whenHasNoItem_doesNotDoAnything() {
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, useCase, handler) = makeSUT()
        sut.invokeCommand = { _ in }
        sut.audioDidStartPlayingItem(item)
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(
            playbackContinuationUseCase: useCase,
            playerHandler: handler
        )
    }
    
    func testAudioDidStartPlayingItem_whenItemhasNoFingerprint_doesNotDoAnything() {
        let node = MockNode(handle: 1, fingerprint: nil)
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let (sut, useCase, handler) = makeSUT()
        sut.invokeCommand = { _ in }
        sut.audioDidStartPlayingItem(item)
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(
            playbackContinuationUseCase: useCase,
            playerHandler: handler
        )
    }
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsStartFromBeginning_doesNotDoAnything() {
        let node = MockNode(handle: 1, fingerprint: anyString())
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let (sut, useCase, handler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .startFromBeginning)
        )
        sut.invokeCommand = { _ in }
        sut.audioDidStartPlayingItem(item)
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(
            playbackContinuationUseCase: useCase,
            playerHandler: handler
        )
    }
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsResumeSession_resumesPlayback() async {
        let exp = expectation(description: #function)
        let node = MockNode(handle: 1, fingerprint: anyString())
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let expectedTime: TimeInterval = 42
        let (sut, _, handler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .resumeSession(playbackTime: expectedTime))
        )
        handler.onPlayerResumePlaybackCompletion = { exp.fulfill() }
        sut.invokeCommand = { _ in }
        sut.audioDidStartPlayingItem(item)
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(handler.playerResumePlayback_Calls, [expectedTime])
    }
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsDisplayDialog_resumesPlayback() async {
        let exp = expectation(description: #function)
        let node = MockNode(handle: 1, fingerprint: anyString())
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let expectedTime: TimeInterval = 42
        let (sut, useCase, handler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .displayDialog(playbackTime: expectedTime))
        )
        handler.onPlayerResumePlaybackCompletion = { exp.fulfill() }
        sut.invokeCommand = { _ in }
        sut.audioDidStartPlayingItem(item)
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(useCase.setPreference_Calls, [.resumePreviousSession])
        XCTAssertEqual(handler.playerResumePlayback_Calls, [expectedTime])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        playbackContinuationUseCase: MockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: MiniPlayerViewModel,
        playbackContinuationUseCase: MockPlaybackContinuationUseCase,
        playerHandler: MockAudioPlayerHandler
    ) {
        let handler = MockAudioPlayerHandler()
        let router = MockMiniPlayerViewRouter()
        let sut = MiniPlayerViewModel(
            configEntity: AudioPlayerConfigEntity(
                node: nil,
                isFolderLink: false,
                fileLink: nil,
                relatedFiles: nil
            ),
            playerHandler: handler,
            router: router,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository(violatesTermsOfServiceResult: .success(false))),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: playbackContinuationUseCase,
            audioPlayerUseCase: MockAudioPlayerUseCase()
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)
        return (sut, playbackContinuationUseCase, handler)
    }
    
    private func assertThatAudioDidStartPlayingItemDoesNotDoAnything(
        playbackContinuationUseCase: MockPlaybackContinuationUseCase,
        playerHandler: MockAudioPlayerHandler,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(playbackContinuationUseCase.setPreference_Calls.isEmpty, file: file, line: line)
        XCTAssertTrue(playerHandler.playerResumePlayback_Calls.isEmpty, file: file, line: line)
    }
    
    private func anyUrl() -> URL { URL(string: "https://any-url.com")! }
    private func anyIndexPath() -> IndexPath { IndexPath(row: 0, section: 0) }
    private func anyQueuePlayer() -> AVQueuePlayer { AVQueuePlayer() }
    private func anyString() -> String { "any-string" }
}
