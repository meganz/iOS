import MEGADomain
import MEGADomainMock
import MediaPlayer
@testable import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing
import UIKit

@MainActor
struct VideoNowPlayingControllerTests {

    // MARK: - Helper

    private func makeSUT(
        player: MockVideoPlayer = MockVideoPlayer(),
        infoCenter: MockNowPlayingInfoCenter = MockNowPlayingInfoCenter(),
        commandCenter: MockNowPlayingRemoteCommandCenter = MockNowPlayingRemoteCommandCenter(),
        artworkProvider: MockVideoNowPlayingArtworkProvider = MockVideoNowPlayingArtworkProvider()
    ) -> VideoNowPlayingController {
        VideoNowPlayingController(
            player: player,
            infoCenter: infoCenter,
            commandCenter: commandCenter,
            artworkProvider: artworkProvider
        )
    }

    private func makeImage(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in }
    }

    private func artworkSize(in infoCenter: MockNowPlayingInfoCenter) -> CGSize? {
        (infoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)?.bounds.size
    }

    // MARK: - Lifecycle

    @Test
    func start_registersCommandsWithOverlaySkipIntervalAndEnablesThem() {
        let player = MockVideoPlayer(canPlayNext: true)
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(player: player, commandCenter: commandCenter)

        sut.start()

        #expect(sut.isActive)
        #expect(commandCenter.registeredSkipIntervals == [15])
        #expect(commandCenter.enabledStates.last?.enabled == true)
        #expect(commandCenter.enabledStates.last?.canPlayNext == true)
    }

    @Test
    func start_calledTwice_registersOnce() {
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(commandCenter: commandCenter)

        sut.start()
        sut.start()

        #expect(commandCenter.registeredSkipIntervals.count == 1)
    }

    @Test
    func canPlayNextChange_updatesNextTrackAvailability() {
        let player = MockVideoPlayer(canPlayNext: true)
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(player: player, commandCenter: commandCenter)
        sut.start()

        player.canPlayNext = false

        #expect(commandCenter.enabledStates.last?.enabled == true)
        #expect(commandCenter.enabledStates.last?.canPlayNext == false)
    }

    @Test
    func stop_clearsInfoAndUnregistersCommands() {
        let infoCenter = MockNowPlayingInfoCenter()
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(infoCenter: infoCenter, commandCenter: commandCenter)
        sut.start()

        sut.stop()

        #expect(sut.isActive == false)
        #expect(infoCenter.nowPlayingInfo == nil)
        #expect(commandCenter.unregisterCallCount == 1)
    }

    @Test
    func stop_stopsPublishingPlayerUpdates() {
        let player = MockVideoPlayer()
        let infoCenter = MockNowPlayingInfoCenter()
        let sut = makeSUT(player: player, infoCenter: infoCenter)
        sut.start()
        sut.stop()

        player.nodeName = "Another video"

        #expect(infoCenter.nowPlayingInfo == nil)
    }

    @Test
    func stop_withoutStart_doesNothing() {
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(commandCenter: commandCenter)

        sut.stop()

        #expect(commandCenter.unregisterCallCount == 0)
    }

    // MARK: - Now Playing info

    @Test
    func start_whilePlaying_publishesTitleTimingAndRate() throws {
        let player = MockVideoPlayer(state: .playing, currentTime: .seconds(30), duration: .seconds(120), nodeName: "Holiday.mp4")
        player.changeRateValue = 1.5
        let infoCenter = MockNowPlayingInfoCenter()
        let sut = makeSUT(player: player, infoCenter: infoCenter)

        sut.start()

        let info = try #require(infoCenter.nowPlayingInfo)
        #expect(info[MPMediaItemPropertyTitle] as? String == "Holiday.mp4")
        #expect(info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval == 30)
        #expect(info[MPMediaItemPropertyPlaybackDuration] as? TimeInterval == 120)
        #expect(info[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 1.5)
        #expect(info[MPNowPlayingInfoPropertyMediaType] as? UInt == MPNowPlayingInfoMediaType.video.rawValue)
    }

    @Test(arguments: [PlaybackState.paused, .buffering, .opening, .ended, .stopped, .error("failed")])
    func notPlaying_publishesZeroRate(state: PlaybackState) throws {
        let player = MockVideoPlayer(state: state, currentTime: .seconds(10), duration: .seconds(60))
        let infoCenter = MockNowPlayingInfoCenter()
        let sut = makeSUT(player: player, infoCenter: infoCenter)

        sut.start()

        let info = try #require(infoCenter.nowPlayingInfo)
        #expect(info[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 0)
    }

    @Test
    func unknownDuration_isLeftOutAndElapsedIsClampedToZero() throws {
        let player = MockVideoPlayer(currentTime: .seconds(-1), duration: .seconds(-1))
        let infoCenter = MockNowPlayingInfoCenter()
        let sut = makeSUT(player: player, infoCenter: infoCenter)

        sut.start()

        let info = try #require(infoCenter.nowPlayingInfo)
        #expect(info[MPMediaItemPropertyPlaybackDuration] == nil)
        #expect(info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval == 0)
    }

    @Test
    func playerUpdates_refreshNowPlayingInfo() throws {
        let player = MockVideoPlayer(state: .paused, currentTime: .seconds(0), duration: .seconds(60), nodeName: "First.mp4")
        let infoCenter = MockNowPlayingInfoCenter()
        let sut = makeSUT(player: player, infoCenter: infoCenter)
        sut.start()

        player.nodeName = "Second.mp4"
        player.currentTime = .seconds(5)
        player.state = .playing

        let info = try #require(infoCenter.nowPlayingInfo)
        #expect(info[MPMediaItemPropertyTitle] as? String == "Second.mp4")
        #expect(info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval == 5)
        #expect(info[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 1)
    }

    // MARK: - Artwork

    @Test
    func artwork_showsFileTypeIconWhileThumbnailLoads() async {
        let player = MockVideoPlayer(state: .paused)
        player.currentItem = .node(MockPlayableNode(handle: 7, name: "Holiday.mp4"))
        let infoCenter = MockNowPlayingInfoCenter()
        let artworkProvider = MockVideoNowPlayingArtworkProvider(placeholderSize: CGSize(width: 24, height: 24))
        let sut = makeSUT(player: player, infoCenter: infoCenter, artworkProvider: artworkProvider)

        sut.start()

        #expect(artworkProvider.placeholderNames == ["Holiday.mp4"])
        #expect(artworkSize(in: infoCenter) == CGSize(width: 24, height: 24))
        await sut.artworkTask?.value
    }

    @Test
    func artwork_thumbnailReplacesFileTypeIcon() async {
        let player = MockVideoPlayer(state: .paused)
        player.currentItem = .node(MockPlayableNode(handle: 7, name: "Holiday.mp4"))
        let infoCenter = MockNowPlayingInfoCenter()
        let artworkProvider = MockVideoNowPlayingArtworkProvider(thumbnails: [7: makeImage(size: CGSize(width: 40, height: 30))])
        let sut = makeSUT(player: player, infoCenter: infoCenter, artworkProvider: artworkProvider)

        sut.start()
        await sut.artworkTask?.value

        #expect(await artworkProvider.requestedHandles == [7])
        #expect(artworkSize(in: infoCenter) == CGSize(width: 40, height: 30))
    }

    @Test
    func artwork_withoutThumbnail_keepsFileTypeIcon() async {
        let player = MockVideoPlayer(state: .playing)
        player.currentItem = .node(MockPlayableNode(handle: 7, name: "Holiday.mp4"))
        player.mockSnapshotImage = makeImage(size: CGSize(width: 16, height: 9))
        let infoCenter = MockNowPlayingInfoCenter()
        let artworkProvider = MockVideoNowPlayingArtworkProvider(placeholderSize: CGSize(width: 24, height: 24))
        let sut = makeSUT(player: player, infoCenter: infoCenter, artworkProvider: artworkProvider)

        sut.start()
        await sut.artworkTask?.value

        #expect(artworkSize(in: infoCenter) == CGSize(width: 24, height: 24))
        #expect(player.captureSnapshotCallCount == 0)
    }

    @Test
    func artwork_nodeChange_resetsToIconAndLoadsNewThumbnail() async {
        let player = MockVideoPlayer(state: .paused)
        player.currentItem = .node(MockPlayableNode(handle: 1, name: "First.mp4"))
        let infoCenter = MockNowPlayingInfoCenter()
        let artworkProvider = MockVideoNowPlayingArtworkProvider(thumbnails: [
            1: makeImage(size: CGSize(width: 10, height: 10)),
            2: makeImage(size: CGSize(width: 20, height: 20))
        ])
        let sut = makeSUT(player: player, infoCenter: infoCenter, artworkProvider: artworkProvider)
        sut.start()
        await sut.artworkTask?.value

        player.currentItem = .node(MockPlayableNode(handle: 2, name: "Second.mp4"))
        player.nodeName = "Second.mp4"
        await sut.artworkTask?.value

        #expect(artworkProvider.placeholderNames == ["First.mp4", "Second.mp4"])
        #expect(await artworkProvider.requestedHandles == [1, 2])
        #expect(artworkSize(in: infoCenter) == CGSize(width: 20, height: 20))
    }

    @Test
    func artwork_renameOfSameNode_doesNotReload() async {
        let player = MockVideoPlayer(state: .paused)
        player.currentItem = .node(MockPlayableNode(handle: 1, name: "First.mp4"))
        let artworkProvider = MockVideoNowPlayingArtworkProvider(thumbnails: [1: makeImage(size: CGSize(width: 10, height: 10))])
        let sut = makeSUT(player: player, artworkProvider: artworkProvider)
        sut.start()
        await sut.artworkTask?.value

        player.nodeName = "Renamed.mp4"
        await sut.artworkTask?.value

        #expect(await artworkProvider.requestedHandles == [1])
    }

    @Test
    func stop_cancelsPendingThumbnailAndClearsInfo() async {
        let player = MockVideoPlayer(state: .paused)
        player.currentItem = .node(MockPlayableNode(handle: 7, name: "Holiday.mp4"))
        let infoCenter = MockNowPlayingInfoCenter()
        let artworkProvider = MockVideoNowPlayingArtworkProvider(thumbnails: [7: makeImage(size: CGSize(width: 40, height: 30))])
        let sut = makeSUT(player: player, infoCenter: infoCenter, artworkProvider: artworkProvider)
        sut.start()
        let pendingArtwork = sut.artworkTask

        sut.stop()
        await pendingArtwork?.value

        #expect(infoCenter.nowPlayingInfo == nil)
    }

    // MARK: - Remote commands

    @Test
    func registeredHandler_routesCommandsToPlayer() {
        let player = MockVideoPlayer(state: .playing)
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(player: player, commandCenter: commandCenter)
        sut.start()

        commandCenter.handler?(.pause)

        #expect(player.pauseCallCount == 1)
    }

    @Test(arguments: [PlaybackState.paused, .opening])
    func play_resumesPlayback(state: PlaybackState) {
        let player = MockVideoPlayer(state: state)
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.play)

        #expect(player.playCallCount == 1)
        #expect(player.seekTimes.isEmpty)
    }

    @Test(arguments: [PlaybackState.ended, .stopped])
    func play_afterPlaybackFinished_restartsFromBeginning(state: PlaybackState) {
        let player = MockVideoPlayer(state: state)
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.play)

        #expect(player.seekTimes == [0])
        #expect(player.playCallCount == 1)
    }

    @Test
    func play_afterError_replaysCurrentNode() {
        let player = MockVideoPlayer(state: .error("failed"))
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.play)

        #expect(player.replayCurrentNodeCallCount == 1)
        #expect(player.playCallCount == 0)
    }

    @Test
    func pause_pausesPlayback() {
        let player = MockVideoPlayer(state: .playing)
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.pause)

        #expect(player.pauseCallCount == 1)
    }

    @Test(arguments: [PlaybackState.playing, .buffering])
    func togglePlayPause_whilePlaying_pauses(state: PlaybackState) {
        let player = MockVideoPlayer(state: state)
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.togglePlayPause)

        #expect(player.pauseCallCount == 1)
        #expect(player.playCallCount == 0)
    }

    @Test
    func togglePlayPause_whilePaused_plays() {
        let player = MockVideoPlayer(state: .paused)
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.togglePlayPause)

        #expect(player.playCallCount == 1)
        #expect(player.pauseCallCount == 0)
    }

    @Test
    func skipForward_jumpsForwardByEventInterval() {
        let player = MockVideoPlayer()
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.skipForward(15))

        #expect(player.jumpForwardCallCount == 1)
        #expect(player.jumpForwardSeconds == 15)
    }

    @Test
    func skipBackward_jumpsBackwardByEventInterval() {
        let player = MockVideoPlayer()
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.skipBackward(15))

        #expect(player.jumpBackwardCallCount == 1)
        #expect(player.jumpBackwardSeconds == 15)
    }

    @Test
    func changePlaybackPosition_seeksToPosition() {
        let player = MockVideoPlayer()
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.changePlaybackPosition(42))

        #expect(player.seekTimes == [42])
    }

    @Test(arguments: [true, false])
    func nextTrack_playsNextOnlyWhenAvailable(canPlayNext: Bool) {
        let player = MockVideoPlayer(canPlayNext: canPlayNext)
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.nextTrack)

        #expect(player.playNextCallCount == (canPlayNext ? 1 : 0))
    }

    @Test
    func previousTrack_playsPrevious() {
        let player = MockVideoPlayer()
        let sut = makeSUT(player: player)
        sut.start()

        sut.handle(.previousTrack)

        #expect(player.playPreviousCallCount == 1)
    }

    @Test
    func commands_afterStop_areIgnored() {
        let player = MockVideoPlayer(state: .paused)
        let sut = makeSUT(player: player)
        sut.start()
        sut.stop()

        sut.handle(.play)

        #expect(player.playCallCount == 0)
    }
}

// MARK: - Mocks

@MainActor
final class MockNowPlayingInfoCenter: NowPlayingInfoCenterProtocol {
    var nowPlayingInfo: [String: Any]?
}

@MainActor
final class MockNowPlayingRemoteCommandCenter: NowPlayingRemoteCommandCenterProtocol {
    private(set) var registeredSkipIntervals: [TimeInterval] = []
    private(set) var handler: (@Sendable @MainActor (NowPlayingRemoteCommand) -> Void)?
    private(set) var enabledStates: [(enabled: Bool, canPlayNext: Bool)] = []
    private(set) var unregisterCallCount = 0

    func register(
        skipInterval: TimeInterval,
        handler: @escaping @Sendable @MainActor (NowPlayingRemoteCommand) -> Void
    ) {
        registeredSkipIntervals.append(skipInterval)
        self.handler = handler
    }

    func setEnabled(_ enabled: Bool, canPlayNext: Bool) {
        enabledStates.append((enabled, canPlayNext))
    }

    func unregister() {
        unregisterCallCount += 1
        handler = nil
    }
}

final class MockVideoNowPlayingArtworkProvider: VideoNowPlayingArtworkProviding, @unchecked Sendable {
    private let thumbnails: [HandleEntity: UIImage]
    private let placeholderImage: UIImage
    private let lock = NSLock()
    private var _placeholderNames: [String] = []
    private var _requestedHandles: [HandleEntity] = []

    var placeholderNames: [String] { lock.withLock { _placeholderNames } }
    var requestedHandles: [HandleEntity] { get async { lock.withLock { _requestedHandles } } }

    init(thumbnails: [HandleEntity: UIImage] = [:], placeholderSize: CGSize = CGSize(width: 1, height: 1)) {
        self.thumbnails = thumbnails
        self.placeholderImage = UIGraphicsImageRenderer(size: placeholderSize).image { _ in }
    }

    func placeholder(forNodeName name: String) -> UIImage {
        lock.withLock { _placeholderNames.append(name) }
        return placeholderImage
    }

    func thumbnail(forNodeHandle handle: HandleEntity) async -> UIImage? {
        lock.withLock { _requestedHandles.append(handle) }
        return thumbnails[handle]
    }
}
