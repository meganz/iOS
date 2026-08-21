@testable import MEGAAudioPlayer
import Testing

@Suite("PlayerLoadingState mapping")
struct PlayerLoadingStateTests {
    @Test(
        "a track that has neither played nor resolved is still starting up",
        arguments: [
            PlaybackStatus.idle,
            .loading,
            .buffering,
            .paused
        ]
    )
    func notReadyAndNeverPlayedIsLoading(status: PlaybackStatus) {
        #expect(
            PlayerLoadingState(
                status: status,
                hasStartedPlayback: false,
                isReady: false
            ) == .loading
        )
    }

    /// Artwork can take longer to parse than the first frame takes to arrive, and
    /// `.loading` disables every control — a track the user can hear must be one
    /// they can pause.
    @Test("audible playback is never held behind the readiness gate", arguments: [false, true])
    func playingIgnoresReadiness(isReady: Bool) {
        #expect(
            PlayerLoadingState(
                status: .playing,
                hasStartedPlayback: false,
                isReady: isReady
            ) == .playing
        )
    }

    @Test("pausing a track that has played keeps the screen it already drew")
    func pauseAfterPlaybackIsPausedEvenIfUnresolved() {
        #expect(
            PlayerLoadingState(
                status: .paused,
                hasStartedPlayback: true,
                isReady: false
            ) == .paused
        )
    }

    @Test("an emptied engine reads as loading, not as a paused track")
    func idleIsLoadingEvenWhenReady() {
        #expect(PlayerLoadingState(status: .idle, hasStartedPlayback: false, isReady: true) == .loading)
    }

    @Test("the session starting a track up reads as loading")
    func loadingIsLoadingEvenWhenReady() {
        #expect(PlayerLoadingState(status: .loading, hasStartedPlayback: false, isReady: true) == .loading)
    }

    /// The screen can already be drawn — artwork and duration are in — but the
    /// track has yet to produce a frame, so it stays on the start-up layout.
    @Test("a resolved track waiting for its first frame is ready, not buffering")
    func stallBeforeTheFirstFrameIsReady() {
        #expect(PlayerLoadingState(status: .buffering, hasStartedPlayback: false, isReady: true) == .ready)
    }

    /// Its own state rather than `.ready`: a stall must not drop the screen back
    /// to the start-up layout, only swap the centre control for the throbber.
    @Test("a mid-track stall gets its own state, not the start-up one")
    func stallPastTheGateIsBuffering() {
        #expect(PlayerLoadingState(status: .buffering, hasStartedPlayback: true, isReady: true) == .buffering)
    }

    @Test("past the gate the centre control follows the engine", arguments: [false, true])
    func readyFollowsStatus(hasStartedPlayback: Bool) {
        #expect(
            PlayerLoadingState(
                status: .playing,
                hasStartedPlayback: hasStartedPlayback,
                isReady: true
            ) == .playing
        )
        #expect(
            PlayerLoadingState(
                status: .paused,
                hasStartedPlayback: hasStartedPlayback,
                isReady: true
            ) == .paused
        )
    }

    /// A stall before the first frame stays on the start-up layout even once the
    /// track has resolved, so it must not be confused with a mid-track stall.
    @Test("an unresolved stall before the first frame is still start-up")
    func stallBeforeTheFirstFrameWithoutMetadataIsLoading() {
        #expect(
            PlayerLoadingState(
                status: .buffering,
                hasStartedPlayback: false,
                isReady: false
            ) == .loading
        )
    }

    /// A failed track never reports a duration or artwork, so deferring to
    /// `isReady` would leave the throbber spinning forever.
    @Test("an error short-circuits the readiness gate", arguments: [false, true])
    func errorIsPausedRegardlessOfReadiness(isReady: Bool) {
        #expect(
            PlayerLoadingState(
                status: .error("boom"),
                hasStartedPlayback: false,
                isReady: isReady
            ) == .paused
        )
    }

    @Test("only the icon states can be toggled")
    func toggleEnabledMatchesTheIconStates() {
        #expect(PlayerLoadingState.playing.isToggleEnabled)
        #expect(PlayerLoadingState.paused.isToggleEnabled)
        #expect(!PlayerLoadingState.loading.isToggleEnabled)
        #expect(!PlayerLoadingState.ready.isToggleEnabled)
        #expect(!PlayerLoadingState.buffering.isToggleEnabled)
    }
}
