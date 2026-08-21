import AVFoundation
@testable import MEGAAudioPlayer
import Testing

@MainActor
@Suite("PlaybackEngine status mapping")
struct PlaybackEngineStatusTests {

    /// `AVPlayer` reports `.paused` both for a held track and for a player with
    /// nothing in it. Reading the empty player as `.paused` is what used to make
    /// the admission check — during which the item is deliberately unloaded —
    /// look like the user had paused, play icon and all.
    @Test(
        "an unloaded player is idle, whatever the time control status says",
        arguments: [
            AVPlayer.TimeControlStatus.paused,
            .waitingToPlayAtSpecifiedRate,
            .playing
        ]
    )
    func unloadedPlayerIsIdle(timeControlStatus: AVPlayer.TimeControlStatus) {
        #expect(
            PlaybackEngine.playbackStatus(from: timeControlStatus, isLoaded: false) == .idle
        )
    }

    @Test("a loaded player maps its time control status through")
    func loadedPlayerMapsTimeControlStatus() {
        #expect(PlaybackEngine.playbackStatus(from: .paused, isLoaded: true) == .paused)
        #expect(PlaybackEngine.playbackStatus(from: .waitingToPlayAtSpecifiedRate, isLoaded: true) == .buffering)
        #expect(PlaybackEngine.playbackStatus(from: .playing, isLoaded: true) == .playing)
    }
}
