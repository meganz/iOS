@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
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
        let currentTime = 0.0
        let remainingTime = 0.0
        let percentageCompleted: Float = 40
        let isPlaying = true
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: anyQueuePlayer(), currentTime: currentTime, remainingTime: remainingTime, percentageCompleted: percentageCompleted, isPlaying: isPlaying)
            },
            expectedCommands: [
                .reloadPlayerStatus(percentage: percentageCompleted, isPlaying: isPlaying)
            ]
        )
    }
    
    // MARK: - audioPlayerCurrentItemCurrentThumbnail
    
    @MainActor
    func testAudioPlayerCurrentItemCurrentThumbnail_whenCalled_reloadsNodeInfoThumbnailOnly() async {
        let expectedThumbnail = testSpecificThumbnail()
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: anyQueuePlayer(), currentItem: nil, currentThumbnail: expectedThumbnail)
            },
            expectedCommands: [
                .reloadNodeInfo(thumbnail: expectedThumbnail)
            ]
        )
    }
    
    // MARK: - audioPlayerNameArtistThumbnailUrl
    
    @MainActor
    func testAudioPlayerNameArtistThumbnailUrl_whenCalled_reloadsNodeInfoThumbnailOnly() async {
        let expectedThumbnail = testSpecificThumbnail()
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: anyQueuePlayer(), name: anyString(), artist: anyString(), thumbnail: expectedThumbnail, url: anyString())
            },
            expectedCommands: [
                .reloadNodeInfo(thumbnail: expectedThumbnail)
            ]
        )
    }
    
    // MARK: - audioPlayerNameArtistThumbnail
    
    @MainActor
    func testAudioPlayerNameArtistThumbnail_whenCalled_reloadsNodeInfoThumbnailOnly() async {
        let expectedThumbnail = testSpecificThumbnail()
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: anyQueuePlayer(), name: anyString(), artist: anyString(), thumbnail: expectedThumbnail)
            },
            expectedCommands: [
                .reloadNodeInfo(thumbnail: expectedThumbnail)
            ]
        )
    }
    
    // MARK: - audioPlayerCurrentItemIndexPath
    
    @MainActor func testAudioPlayerCurrentItemIndexPath_whenNils_doesNotChangeCurrentItemAtIndexPath() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), currentItem: nil, indexPath: nil)
        
        XCTAssertTrue(receivedCommands.isEmpty, "Expect to received no commands to update the UI")
    }
    
    @MainActor
    func testAudioPlayerCurrentItemIndexPath_whenCalled_changesCurrentItemAtIndexPath() async {
        let expectedCurrentItem = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let expectedIndexPath = anyIndexPath()
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: anyQueuePlayer(), currentItem: expectedCurrentItem, indexPath: expectedIndexPath)
            },
            expectedCommands: [
                .change(currentItem: expectedCurrentItem, indexPath: expectedIndexPath)
            ]
        )
    }
    
    @MainActor
    func testAudioPlayerReloadItemIndexPath_whenItemIsNil_doesNotReloadItem() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), reload: nil)
        
        XCTAssertTrue(receivedCommands.isEmpty, "Expect to received no commands to update the UI")
    }
    
    @MainActor
    func testAudioPlayerReloadItem_whenHasItem_reloadsItem() async {
        let itemToReload = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audio(player: anyQueuePlayer(), reload: itemToReload)
            },
            expectedCommands: [
                .reload(currentItem: itemToReload)
            ]
        )
    }
    
    // MARK: - audioPlayerWillStartBlockingAction
    
    @MainActor func testAudioPlayerWillStartBlockingAction_whenCalled_disableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audioPlayerWillStartBlockingAction()
            },
            expectedCommands: [
                .enableUserInteraction(false)
            ]
        )
    }
    
    // MARK: - audioPlayerDidFinishBlockingAction
    
    @MainActor func testAudioPlayerDidFinishBlockingAction_whenCalled_enableUserInteraction() async {
        let (sut, _, _) = makeSUT()
        
        await test(
            viewModel: sut,
            trigger: {
                sut.audioPlayerDidFinishBlockingAction()
            },
            expectedCommands: [
                .enableUserInteraction(true)
            ]
        )
    }
    
    // MARK: - audioDidStartPlayingItem
    
    @MainActor func testAudioDidStartPlayingItem_whenHasNoItem_doesNotDoAnything() {
        let itemToPlay = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, playbackContinuationUseCase, playerHandler) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioDidStartPlayingItem(itemToPlay)
        
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(playbackContinuationUseCase: playbackContinuationUseCase, playerHandler: playerHandler)
    }
    
    @MainActor func testAudioDidStartPlayingItem_whenItemhasNoFingerprint_doesNotDoAnything() {
        let node = MockNode(handle: 1, fingerprint: nil)
        let itemToPlayWithoutFingerprint = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let (sut, playbackContinuationUseCase, playerHandler) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioDidStartPlayingItem(itemToPlayWithoutFingerprint)
        
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(playbackContinuationUseCase: playbackContinuationUseCase, playerHandler: playerHandler)
    }
    
    @MainActor func testAudioDidStartPlayingItem_whenPlaybackStatusIsStartFromBeginning_doesNotDoAnything() {
        let node = MockNode(handle: 1, fingerprint: anyString())
        let itemToPlayWithFingerprint = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let (sut, playbackContinuationUseCase, playerHandler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .startFromBeginning)
        )
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioDidStartPlayingItem(itemToPlayWithFingerprint)
        
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(playbackContinuationUseCase: playbackContinuationUseCase, playerHandler: playerHandler)
    }
    
    @MainActor func testAudioDidStartPlayingItem_whenPlaybackStatusIsResumeSession_resumesPlayback() {
        let node = MockNode(handle: 1, fingerprint: anyString())
        let itemToPlayWithFingerprint = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let expectedPlaybackTime: TimeInterval = .infinity
        let (sut, _, playerHandler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .resumeSession(playbackTime: expectedPlaybackTime))
        )
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioDidStartPlayingItem(itemToPlayWithFingerprint)
        
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [ expectedPlaybackTime ])
    }
    
    @MainActor func testAudioDidStartPlayingItem_whenPlaybackStatusIsDisplayDialog_resumesPlayback() {
        let node = MockNode(handle: 1, fingerprint: anyString())
        let itemToPlayWithFingerprint = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let expectedPlaybackTime: TimeInterval = .infinity
        let (sut, playbackContinuationUseCase, playerHandler) = makeSUT(
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(status: .displayDialog(playbackTime: expectedPlaybackTime))
        )
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioDidStartPlayingItem(itemToPlayWithFingerprint)
        
        XCTAssertEqual(playbackContinuationUseCase.setPreference_Calls, [ .resumePreviousSession ])
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [ expectedPlaybackTime ])
    }
    
    // MARK: - Test Helpers
    
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
        let mockRouter = MockMiniPlayerViewRouter()
        let mockPlayerHandler = MockAudioPlayerHandler()
        let mockAudioPlayerUseCase = MockAudioPlayerUseCase()
        let sut = MiniPlayerViewModel(
            configEntity: AudioPlayerConfigEntity(
                node: nil,
                isFolderLink: false,
                fileLink: nil,
                relatedFiles: nil,
                playerHandler: mockPlayerHandler
            ),
            router: mockRouter,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: playbackContinuationUseCase,
            audioPlayerUseCase: mockAudioPlayerUseCase
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
        XCTAssertTrue(playbackContinuationUseCase.setPreference_Calls.isEmpty, "Expect to not call setPreference on playbackContinuationUseCase", file: file, line: line)
        XCTAssertTrue(playerHandler.playerResumePlayback_Calls.isEmpty, "Expect to not call player resume playback", file: file, line: line)
    }
    
    private func anyUrl() -> URL {
        URL(string: "https://any-url.com")!
    }
    
    private func anyIndexPath() -> IndexPath {
        IndexPath(row: 0, section: 0)
    }
    
    private func anyQueuePlayer() -> AVQueuePlayer {
        AVQueuePlayer()
    }
    
    private func anyString() -> String {
        "any-string"
    }
    
    private func testSpecificThumbnail() -> UIImage {
        UIImage(systemName: "person")!
    }
}
