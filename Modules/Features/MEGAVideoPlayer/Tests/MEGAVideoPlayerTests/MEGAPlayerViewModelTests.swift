@testable import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing
import UIKit

@MainActor
struct MEGAPlayerViewModelTests {

    // MARK: - Helper

    private func makeSUT(
        player: MockVideoPlayer = MockVideoPlayer(),
        infoCenter: MockNowPlayingInfoCenter = MockNowPlayingInfoCenter(),
        commandCenter: MockNowPlayingRemoteCommandCenter = MockNowPlayingRemoteCommandCenter(),
        onPlaybackStarted: (() -> Void)? = nil
    ) -> MEGAPlayerViewModel {
        let sut = MEGAPlayerViewModel(
            player: player,
            nowPlayingController: VideoNowPlayingController(
                player: player,
                infoCenter: infoCenter,
                commandCenter: commandCenter,
                artworkProvider: MockVideoNowPlayingArtworkProvider()
            )
        )
        sut.onPlaybackStarted = onPlaybackStarted
        sut.viewDidLoad(playerView: UIView())
        return sut
    }

    // MARK: - Starting playback

    @Test
    func viewDidLoad_runsOnPlaybackStartedOnceBeforeTakingNowPlaying() {
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        var registerCallCounts: [Int] = []

        _ = makeSUT(
            commandCenter: commandCenter,
            onPlaybackStarted: { registerCallCounts.append(commandCenter.registeredSkipIntervals.count) }
        )

        #expect(registerCallCounts == [0])
        #expect(commandCenter.registeredSkipIntervals.count == 1)
    }

    // MARK: - Node deletion

    @Test
    func nodeDeleted_endsPlaybackThenDismisses() {
        let player = MockVideoPlayer(state: .playing)
        let infoCenter = MockNowPlayingInfoCenter()
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(player: player, infoCenter: infoCenter, commandCenter: commandCenter)
        var stopCallCountWhenDismissed: Int?
        sut.dismissAction = { stopCallCountWhenDismissed = player.stopCallCount }

        player.onNodeDeleted?()

        #expect(player.stopCallCount == 1)
        #expect(commandCenter.unregisterCallCount == 1)
        #expect(infoCenter.nowPlayingInfo == nil)
        #expect(stopCallCountWhenDismissed == 1)
    }

    @Test
    func nodeDeleted_runsNodeDeletedActionBeforeEndingPlayback() {
        let player = MockVideoPlayer(state: .playing)
        let sut = makeSUT(player: player)
        var stopCallCountWhenNodeDeletedActionRan: Int?
        sut.nodeDeletedAction = { stopCallCountWhenNodeDeletedActionRan = player.stopCallCount }

        player.onNodeDeleted?()

        #expect(stopCallCountWhenNodeDeletedActionRan == 0)
        #expect(player.stopCallCount == 1)
    }

    // MARK: - Ending playback

    @Test
    func viewWillDismiss_calledAgain_endsPlaybackOnlyOnce() {
        let player = MockVideoPlayer(state: .playing)
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(player: player, commandCenter: commandCenter)

        sut.viewWillDismiss()
        sut.viewWillDismiss()

        #expect(sut.hasEndedPlayback)
        #expect(player.stopCallCount == 1)
        #expect(commandCenter.unregisterCallCount == 1)
    }

    @Test
    func viewWillDismiss_runsOnPlaybackEndedOnceAfterReleasingNowPlaying() {
        let commandCenter = MockNowPlayingRemoteCommandCenter()
        let sut = makeSUT(commandCenter: commandCenter)
        var unregisterCallCounts: [Int] = []
        sut.onPlaybackEnded = { unregisterCallCounts.append(commandCenter.unregisterCallCount) }

        sut.viewWillDismiss()
        sut.viewWillDismiss()

        #expect(unregisterCallCounts == [1])
    }

    @Test
    func nodeDeleted_runsOnPlaybackEnded() {
        let player = MockVideoPlayer(state: .playing)
        let sut = makeSUT(player: player)
        var onPlaybackEndedCallCount = 0
        sut.onPlaybackEnded = { onPlaybackEndedCallCount += 1 }

        player.onNodeDeleted?()

        #expect(onPlaybackEndedCallCount == 1)
    }
}
