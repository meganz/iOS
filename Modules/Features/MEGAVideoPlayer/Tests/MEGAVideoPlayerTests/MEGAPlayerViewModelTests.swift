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
        commandCenter: MockNowPlayingRemoteCommandCenter = MockNowPlayingRemoteCommandCenter()
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
        sut.viewDidLoad(playerView: UIView())
        return sut
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
}
