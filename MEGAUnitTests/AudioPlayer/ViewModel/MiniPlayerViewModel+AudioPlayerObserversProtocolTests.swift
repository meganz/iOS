@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

final class MiniPlayerViewModel_AudioPlayerObserversProtocolTests: XCTestCase {
    
    // MARK: - audioPlayerShowLoading
    
    func testAudioPlayerShowLoading_whenCalled_showsLoading() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), showLoading: true)
        
        XCTAssertEqual(receivedCommands, [ .showLoading(true) ])
    }
    
    func testAudioPlayerShowLoading_whenCalled_HidesLoading() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), showLoading: false)
        
        XCTAssertEqual(receivedCommands, [ .showLoading(false) ])
    }
    
    // MARK: - audioPlayerCurrentTime
    
    func testAudioPlayerCurrentTime_whenCalled_reloadsPlayerStatus() {
        let currentTime = 0.0
        let remainingTime = 0.0
        let percentageCompleted: Float = 40
        let isPlaying = true
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), currentTime: currentTime, remainingTime: remainingTime, percentageCompleted: percentageCompleted, isPlaying: isPlaying)
        
        XCTAssertEqual(receivedCommands, [ .reloadPlayerStatus(percentage: percentageCompleted, isPlaying: isPlaying) ])
    }
    
    // MARK: - audioPlayerCurrentItemCurrentThumbnail
    
    func testAudioPlayerCurrentItemCurrentThumbnail_whenCalled_reloadsNodeInfoThumbnailOnly() {
        let expectedThumbnail = testSpecificThumbnail()
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), currentItem: nil, currentThumbnail: expectedThumbnail)
        
        XCTAssertEqual(receivedCommands, [ .reloadNodeInfo(thumbnail: expectedThumbnail) ])
    }
    
    // MARK: - audioPlayerNameArtistThumbnailUrl
    
    func testAudioPlayerNameArtistThumbnailUrl_whenCalled_reloadsNodeInfoThumbnailOnly() {
        let expectedThumbnail = testSpecificThumbnail()
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), name: anyString(), artist: anyString(), thumbnail: expectedThumbnail, url: anyString())
        
        XCTAssertEqual(receivedCommands, [ .reloadNodeInfo(thumbnail: expectedThumbnail) ])
    }
    
    // MARK: - audioPlayerNameArtistThumbnail
    
    func testAudioPlayerNameArtistThumbnail_whenCalled_reloadsNodeInfoThumbnailOnly() {
        let expectedThumbnail = testSpecificThumbnail()
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), name: anyString(), artist: anyString(), thumbnail: expectedThumbnail)
        
        XCTAssertEqual(receivedCommands, [ .reloadNodeInfo(thumbnail: expectedThumbnail) ])
    }
    
    // MARK: - audioPlayerCurrentItemIndexPath
    
    func testAudioPlayerCurrentItemIndexPath_whenNils_doesNotChangeCurrentItemAtIndexPath() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), currentItem: nil, indexPath: nil)
        
        XCTAssertTrue(receivedCommands.isEmpty, "Expect to received no commands to update the UI")
    }
    
    func testAudioPlayerCurrentItemIndexPath_whenCurrentItemIsNil_doesNotChangeCurrentItemAtIndexPath() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), currentItem: nil, indexPath: anyIndexPath())
        
        XCTAssertTrue(receivedCommands.isEmpty, "Expect to received no commands to update the UI")
    }
    
    func testAudioPlayerCurrentItemIndexPath_whenIndexPathIsNil_doesNotChangeCurrentItemAtIndexPath() {
        let currentItem = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), currentItem: currentItem, indexPath: nil)
        
        XCTAssertTrue(receivedCommands.isEmpty, "Expect to received no commands to update the UI")
    }
    
    func testAudioPlayerCurrentItemIndexPath_whenCalled_changesCurrentItemAtIndexPath() {
        let expectedCurrentItem = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let expectedIndexPath = anyIndexPath()
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), currentItem: expectedCurrentItem, indexPath: expectedIndexPath)
        
        XCTAssertEqual(receivedCommands, [ .change(currentItem: expectedCurrentItem, indexPath: expectedIndexPath) ])
    }
    
    func testAudioPlayerReloadItemIndexPath_whenItemIsNil_doesNotReloadItem() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), reload: nil)
        
        XCTAssertTrue(receivedCommands.isEmpty, "Expect to received no commands to update the UI")
    }
    
    func testAudioPlayerReloadItem_whenHasItem_reloadsItem() {
        let itemToReload = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audio(player: anyQueuePlayer(), reload: itemToReload)
        
        XCTAssertEqual(receivedCommands, [ .reload(currentItem: itemToReload) ])
    }
    
    // MARK: - audioPlayerWillStartBlockingAction
    
    func testAudioPlayerWillStartBlockingAction_whenCalled_disableUserInteraction() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioPlayerWillStartBlockingAction()
        
        XCTAssertEqual(receivedCommands, [ .enableUserInteraction(false) ])
    }
    
    // MARK: - audioPlayerDidFinishBlockingAction
    
    func testAudioPlayerDidFinishBlockingAction_whenCalled_enableUserInteraction() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioPlayerDidFinishBlockingAction()
        
        XCTAssertEqual(receivedCommands, [ .enableUserInteraction(true) ])
    }
    
    // MARK: - audioDidStartPlayingItem
    
    func testAudioDidStartPlayingItem_whenHasNoItem_doesNotDoAnything() {
        let itemToPlay = AudioPlayerItem(name: anyString(), url: anyUrl(), node: MockNode(handle: 1))
        let (sut, playbackContinuationUseCase, playerHandler) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioDidStartPlayingItem(itemToPlay)
        
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(playbackContinuationUseCase: playbackContinuationUseCase, playerHandler: playerHandler)
    }
    
    func testAudioDidStartPlayingItem_whenItemhasNoFingerprint_doesNotDoAnything() {
        let node = MockNode(handle: 1, fingerprint: nil)
        let itemToPlayWithoutFingerprint = AudioPlayerItem(name: anyString(), url: anyUrl(), node: node)
        let (sut, playbackContinuationUseCase, playerHandler) = makeSUT()
        var receivedCommands = [MiniPlayerViewModel.Command]()
        sut.invokeCommand = { receivedCommands.append($0) }
        
        sut.audioDidStartPlayingItem(itemToPlayWithoutFingerprint)
        
        assertThatAudioDidStartPlayingItemDoesNotDoAnything(playbackContinuationUseCase: playbackContinuationUseCase, playerHandler: playerHandler)
    }
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsStartFromBeginning_doesNotDoAnything() {
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
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsResumeSession_resumesPlayback() {
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
    
    func testAudioDidStartPlayingItem_whenPlaybackStatusIsDisplayDialog_resumesPlayback() {
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
            playbackContinuationUseCase: playbackContinuationUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
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
