@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

final class MiniPlayerViewModel_AudioPlayerObserversProtocolTests: XCTestCase {
    // MARK: - audioPlayerShowLoading
    @MainActor
    func testAudioPlayerShowLoading_whenCalled_showsLoading() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), showLoading: true) },
            expectedCommands: [.showLoading(true)]
        )
    }

    @MainActor
    func testAudioPlayerShowLoading_whenCalled_HidesLoading() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), showLoading: false) },
            expectedCommands: [.showLoading(false)]
        )
    }

    // MARK: - audioPlayerCurrentTime
    @MainActor
    func testAudioPlayerCurrentTime_whenCalled_reloadsPlayerStatus() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), currentTime: 0, remainingTime: 0, percentageCompleted: 40, isPlaying: true) },
            expectedCommands: [.reloadPlayerStatus(percentage: 40, isPlaying: true)]
        )
    }

    // MARK: - audioPlayerCurrentItemCurrentThumbnail
    @MainActor
    func testAudioPlayerCurrentItemCurrentThumbnail_whenCalled_reloadsNodeInfoThumbnailOnly() async {
        let (sut, _, _) = makeSUT()
        let thumb = testSpecificThumbnail()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), currentItem: nil, currentThumbnail: thumb) },
            expectedCommands: [.reloadNodeInfo(thumbnail: thumb)]
        )
    }

    // MARK: - audioPlayerNameArtistThumbnailUrl
    @MainActor
    func testAudioPlayerNameArtistThumbnailUrl_whenCalled_reloadsNodeInfoThumbnailOnly() async {
        let (sut, _, _) = makeSUT()
        let thumb = testSpecificThumbnail()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), name: anyString(), artist: anyString(), thumbnail: thumb, url: anyString()) },
            expectedCommands: [.reloadNodeInfo(thumbnail: thumb)]
        )
    }

    // MARK: - audioPlayerNameArtistThumbnail
    @MainActor
    func testAudioPlayerNameArtistThumbnail_whenCalled_reloadsNodeInfoThumbnailOnly() async {
        let (sut, _, _) = makeSUT()
        let thumb = testSpecificThumbnail()
        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), name: anyString(), artist: anyString(), thumbnail: thumb) },
            expectedCommands: [.reloadNodeInfo(thumbnail: thumb)]
        )
    }

    // MARK: - audioPlayerCurrentItemIndexPath
    @MainActor
    func testAudioPlayerCurrentItemIndexPath_whenNils_doesNotChangeCurrentItemAtIndexPath() {
        let (sut, _, _) = makeSUT()
        var received = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { received.append($0) }

        sut.audio(player: anyQueuePlayer(), currentItem: nil, indexPath: nil)

        XCTAssertTrue(received.isEmpty, "No commands should be sent when both item and indexPath are nil")
    }

    @MainActor
    func testAudioPlayerCurrentItemIndexPath_whenCalled_changesCurrentItemAtIndexPath() async {
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let indexPath = anyIndexPath()
        let (sut, _, _) = makeSUT()

        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), currentItem: item, indexPath: indexPath) },
            expectedCommands: [.change(currentItem: item, indexPath: indexPath)]
        )
    }

    // MARK: - audioPlayerReloadItemIndexPath
    @MainActor
    func testAudioPlayerReloadItemIndexPath_whenItemIsNil_doesNotReloadItem() {
        let (sut, _, _) = makeSUT()
        var received = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { received.append($0) }

        sut.audio(player: anyQueuePlayer(), reload: nil)

        XCTAssertTrue(received.isEmpty, "No commands should be sent when reload item is nil")
    }

    @MainActor
    func testAudioPlayerReloadItem_whenHasItem_reloadsItem() async {
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, _, _) = makeSUT()

        await test(
            viewModel: sut,
            trigger: { sut.audio(player: anyQueuePlayer(), reload: item) },
            expectedCommands: [.reload(item: item)]
        )
    }

    // MARK: - audioPlayerWillStartBlockingAction
    @MainActor
    func testAudioPlayerWillStartBlockingAction_whenCalled_disableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audioPlayerWillStartBlockingAction() },
            expectedCommands: [.enableUserInteraction(false)]
        )
    }

    // MARK: - audioPlayerDidFinishBlockingAction
    @MainActor
    func testAudioPlayerDidFinishBlockingAction_whenCalled_enableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        await test(
            viewModel: sut,
            trigger: { sut.audioPlayerDidFinishBlockingAction() },
            expectedCommands: [.enableUserInteraction(true)]
        )
    }

    // MARK: - audioDidStartPlayingItem
    @MainActor
    func testAudioDidStartPlayingItem_whenHasNoItem_doesNotDoAnything() {
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, useCase, handler) = makeSUT()
        var received = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { received.append($0) }

        sut.audioDidStartPlayingItem(item)

        assertThatAudioDidStartPlayingItemDoesNotDoAnything(
            playbackContinuationUseCase: useCase,
            playerHandler: handler
        )
    }

    @MainActor
    func testAudioDidStartPlayingItem_whenItemhasNoFingerprint_doesNotDoAnything() {
        let node = MockNode(handle: 1, fingerprint: nil)
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let (sut, useCase, handler) = makeSUT()
        var received = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { received.append($0) }

        sut.audioDidStartPlayingItem(item)

        assertThatAudioDidStartPlayingItemDoesNotDoAnything(
            playbackContinuationUseCase: useCase,
            playerHandler: handler
        )
    }

    @MainActor
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsStartFromBeginning_doesNotDoAnything() {
        let node = MockNode(handle: 1, fingerprint: anyString())
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let (sut, useCase, handler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .startFromBeginning)
        )
        var received = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { received.append($0) }

        sut.audioDidStartPlayingItem(item)

        assertThatAudioDidStartPlayingItemDoesNotDoAnything(
            playbackContinuationUseCase: useCase,
            playerHandler: handler
        )
    }

    @MainActor
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsResumeSession_resumesPlayback() async {
        let expectation = expectation(description: #function)
        let node = MockNode(handle: 1, fingerprint: anyString())
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let expectedTime: TimeInterval = 42
        
        let (sut, _, handler) = makeSUT(playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .resumeSession(playbackTime: expectedTime)))
        handler.onPlayerResumePlaybackCompletion = { expectation.fulfill() }

        sut.invokeCommand = { _ in }
        sut.audioDidStartPlayingItem(item)

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(handler.playerResumePlayback_Calls, [expectedTime])
    }

    @MainActor
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsDisplayDialog_resumesPlayback() async {
        let expectation = expectation(description: #function)
        let node = MockNode(handle: 1, fingerprint: anyString())
        let item = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let expectedTime: TimeInterval = 42

        let (sut, useCase, handler) = makeSUT(playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .displayDialog(playbackTime: expectedTime)))
        handler.onPlayerResumePlaybackCompletion = { expectation.fulfill() }

        sut.invokeCommand = { _ in }
        sut.audioDidStartPlayingItem(item)

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(useCase.setPreference_Calls, [.resumePreviousSession])
        XCTAssertEqual(handler.playerResumePlayback_Calls, [expectedTime])
    }

    // MARK: - Helpers
    @MainActor
    private func makeSUT(
        playbackContinuationUseCase: MockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: MiniPlayerViewModel,
        playbackContinuationUseCase: MockPlaybackContinuationUseCase,
        playerHandler: MockAudioPlayerHandler
    ) {
        let mockPlayerHandler = MockAudioPlayerHandler()
        let mockHandlerBuilder = MockAudioPlayerHandlerBuilder(handler: mockPlayerHandler)
        let router = MockMiniPlayerViewRouter()
        let sut = MiniPlayerViewModel(
            configEntity: AudioPlayerConfigEntity(
                node: nil,
                isFolderLink: false,
                fileLink: nil,
                relatedFiles: nil,
                audioPlayerHandlerBuilder: mockHandlerBuilder
            ),
            router: router,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: playbackContinuationUseCase,
            audioPlayerUseCase: MockAudioPlayerUseCase()
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)

        return (sut, playbackContinuationUseCase, mockPlayerHandler)
    }

    private func assertThatAudioDidStartPlayingItemDoesNotDoAnything(
        playbackContinuationUseCase: MockPlaybackContinuationUseCase,
        playerHandler: MockAudioPlayerHandler,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            playbackContinuationUseCase.setPreference_Calls.isEmpty,
            "Expected no calls to setPreference on continuation use case")
        XCTAssertTrue(playerHandler.playerResumePlayback_Calls.isEmpty,
                      "Expected no calls to resume playback")
    }

    private func anyUrl() -> URL { URL(string: "https://any-url.com")! }
    private func anyIndexPath() -> IndexPath { IndexPath(row: 0, section: 0) }
    private func anyQueuePlayer() -> AVQueuePlayer { AVQueuePlayer() }
    private func anyString() -> String { "any-string" }
    private func testSpecificThumbnail() -> UIImage { UIImage(systemName: "person")! }
}
