@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

@MainActor
@Suite("LegacyAudioTearDownHandler")
struct LegacyAudioTearDownHandlerTests {

    @Test("Dismisses the full screen player and closes it")
    func tearsDownPlayer() async {
        let audioPlayerHandler = MockAudioPlayerHandler(isPlayerDefined: true)
        let sut = LegacyAudioTearDownHandler(audioPlayerHandler: audioPlayerHandler)

        await sut.handleDismiss()

        #expect(audioPlayerHandler.dismissFullScreenPlayer_calledTimes == 1)
        #expect(audioPlayerHandler.closePlayer_calledTimes == 1)
    }

    /// `closePlayer()` with no player still runs `cleanupAfterClose()`, which reconfigures the audio session
    /// to the call category — disruptive when the user is on a call or watching a video.
    @Test("Leaves the player alone when there is none to close")
    func skipsCloseWithoutPlayer() async {
        let audioPlayerHandler = MockAudioPlayerHandler(isPlayerDefined: false)
        let sut = LegacyAudioTearDownHandler(audioPlayerHandler: audioPlayerHandler)

        await sut.handleDismiss()

        #expect(audioPlayerHandler.closePlayer_calledTimes == 0)
    }

    /// The screen and the playback are tracked separately, so a player that is loading, stalled or already
    /// closing — all of which report `isPlayerAlive() == false` — must still have its screen dismissed.
    @Test("Dismisses the player screen even when the player is not alive", arguments: [true, false])
    func dismissesScreenRegardlessOfLiveness(isPlayerDefined: Bool) async {
        let audioPlayerHandler = MockAudioPlayerHandler(isPlayerDefined: isPlayerDefined)
        audioPlayerHandler.playerAlive = false
        let sut = LegacyAudioTearDownHandler(audioPlayerHandler: audioPlayerHandler)

        await sut.handleDismiss()

        #expect(audioPlayerHandler.dismissFullScreenPlayer_calledTimes == 1)
    }
}

@MainActor
@Suite("RevampedAudioTearDownHandler")
struct RevampedAudioTearDownHandlerTests {

    /// The player screen closes by observing the session, so ending the session is the whole teardown.
    @Test("Ends the playback session")
    func endsSession() async {
        var endSessionCallCount = 0
        let sut = RevampedAudioTearDownHandler { endSessionCallCount += 1 }

        await sut.handleDismiss()

        #expect(endSessionCallCount == 1)
    }
}

@MainActor
@Suite("AudioTearDownHandlerFactory")
struct AudioTearDownHandlerFactoryTests {

    @Test("Tears the revamped player down when its flag is on")
    func revampedHandlerWhenFlagOn() {
        let sut = AudioTearDownHandlerFactory.make(featureFlagProvider: provider(audioPlayerRevamp: true))

        #expect(sut is RevampedAudioTearDownHandler)
    }

    @Test("Tears the legacy player down when the flag is off")
    func legacyHandlerWhenFlagOff() {
        let sut = AudioTearDownHandlerFactory.make(featureFlagProvider: provider(audioPlayerRevamp: false))

        #expect(sut is LegacyAudioTearDownHandler)
    }

    private func provider(audioPlayerRevamp: Bool) -> MockFeatureFlagProvider {
        MockFeatureFlagProvider(list: [.audioPlayerRevamp: audioPlayerRevamp])
    }
}
