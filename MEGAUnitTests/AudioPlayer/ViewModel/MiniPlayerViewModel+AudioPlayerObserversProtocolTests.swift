@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class MiniPlayerViewModel_AudioPlayerObserversProtocolTests: XCTestCase {
    private let testTimeout: TimeInterval = 0.1
    private let sampleURL = URL(string: "https://example.com/audio.mp3")!
    private let sampleIndexPath = IndexPath(row: 0, section: 0)
    private let sampleString = "sample-string"
    private let defaultResumeTime: TimeInterval = 42
    
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
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, playbackContinuationUseCase, handler)
    }
    
    private func sampleItem(fingerprint: String? = "fingerprint") -> AudioPlayerItem {
        let node = MockNode(handle: 1, fingerprint: fingerprint)
        return AudioPlayerItem(name: sampleString, url: sampleURL, node: node)
    }
    
    private func assertNoCommandsEmitted(
        trigger: @MainActor () -> Void,
        on sut: MiniPlayerViewModel
    ) async {
        let exp = expectation(description: "no commands")
        exp.isInverted = true
        sut.invokeCommand = { _ in exp.fulfill() }
        trigger()
        await fulfillment(of: [exp], timeout: testTimeout)
    }
    
    private func assertResumeScenario(
        status: PlaybackContinuationStatusEntity,
        expectedPreferenceCalls: [PlaybackContinuationPreferenceStatusEntity]
    ) async {
        let item = sampleItem()
        let exp = expectation(description: "resume playback")
        let (sut, playbackUseCase, playerHandler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: status)
        )
        playerHandler.onPlayerResumePlaybackCompletion = { exp.fulfill() }
        sut.invokeCommand = { _ in XCTFail("No UI commands expected") }
        
        sut.audioDidStartPlayingItem(item)
        
        await fulfillment(of: [exp], timeout: testTimeout)
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [defaultResumeTime])
        XCTAssertEqual(playbackUseCase.setPreference_Calls, expectedPreferenceCalls)
    }
    
    func testAudioPlayerShowLoading_whenCalled_showsLoading() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), showLoading: true) },
            expectedCommands: [.showLoading(true)],
            timeout: testTimeout
        )
    }
    
    func testAudioPlayerShowLoading_whenCalled_HidesLoading() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), showLoading: false) },
            expectedCommands: [.showLoading(false)],
            timeout: testTimeout
        )
    }
    
    func testAudioPlayerCurrentTime_whenCalled_reloadsPlayerStatus() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), currentTime: 0, remainingTime: 0, percentageCompleted: 40, isPlaying: true) },
            expectedCommands: [.reloadPlayerStatus(percentage: 40, isPlaying: true)],
            timeout: testTimeout
        )
    }
    
    func testAudioPlayerCurrentItemIndexPath_whenNils_doesNotChangeCurrentItemAtIndexPath() async {
        let (sut, _, _) = makeSUT()
        await assertNoCommandsEmitted(trigger: { sut.audio(player: AVQueuePlayer(), currentItem: nil, indexPath: nil) }, on: sut)
    }
    
    func testAudioPlayerCurrentItemIndexPath_whenCalled_changesCurrentItemAtIndexPath() async {
        let item = sampleItem()
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), currentItem: item, indexPath: sampleIndexPath) },
            expectedCommands: [.change(currentItem: item, indexPath: sampleIndexPath)],
            timeout: testTimeout
        )
    }
    
    func testAudioPlayerReloadItemIndexPath_whenItemIsNil_doesNotReloadItem() async {
        let (sut, _, _) = makeSUT()
        await assertNoCommandsEmitted(trigger: { sut.audio(player: AVQueuePlayer(), reload: nil) }, on: sut)
    }
    
    func testAudioPlayerReloadItem_whenHasItem_reloadsItem() async {
        let item = sampleItem()
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: AVQueuePlayer(), reload: item) },
            expectedCommands: [.reload(item: item)],
            timeout: testTimeout
        )
    }
    
    func testAudioPlayerWillStartBlockingAction_whenCalled_disableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audioPlayerWillStartBlockingAction() },
            expectedCommands: [.enableUserInteraction(false)],
            timeout: testTimeout
        )
    }
    
    func testAudioPlayerDidFinishBlockingAction_whenCalled_enableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audioPlayerDidFinishBlockingAction() },
            expectedCommands: [.enableUserInteraction(true)],
            timeout: testTimeout
        )
    }
    
    func testAudioDidStartPlayingItem_whenHasNoItem_doesNotDoAnything() async {
        let (sut, playbackUseCase, playerHandler) = makeSUT()
        await assertNoCommandsEmitted(trigger: { sut.audioDidStartPlayingItem(nil) }, on: sut)
        XCTAssertTrue(playbackUseCase.setPreference_Calls.isEmpty)
        XCTAssertTrue(playerHandler.playerResumePlayback_Calls.isEmpty)
    }
    
    func testAudioDidStartPlayingItem_whenItemhasNoFingerprint_doesNotDoAnything() async {
        let itemWithoutFingerprint = sampleItem(fingerprint: nil)
        let (sut, playbackUseCase, playerHandler) = makeSUT()
        await assertNoCommandsEmitted(trigger: { sut.audioDidStartPlayingItem(itemWithoutFingerprint) }, on: sut)
        XCTAssertTrue(playbackUseCase.setPreference_Calls.isEmpty)
        XCTAssertTrue(playerHandler.playerResumePlayback_Calls.isEmpty)
    }
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsStartFromBeginning_doesNotDoAnything() async {
        let item = sampleItem()
        let (sut, playbackUseCase, playerHandler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .startFromBeginning)
        )
        await assertNoCommandsEmitted(trigger: { sut.audioDidStartPlayingItem(item) }, on: sut)
        XCTAssertTrue(playbackUseCase.setPreference_Calls.isEmpty)
        XCTAssertTrue(playerHandler.playerResumePlayback_Calls.isEmpty)
    }
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsResumeSession_resumesPlayback() async {
        await assertResumeScenario(
            status: .resumeSession(playbackTime: defaultResumeTime),
            expectedPreferenceCalls: []
        )
    }
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsDisplayDialog_resumesPlayback() async {
        await assertResumeScenario(
            status: .displayDialog(playbackTime: defaultResumeTime),
            expectedPreferenceCalls: [.resumePreviousSession]
        )
    }
}
