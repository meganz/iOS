import AVFoundation
import Combine
@testable import MEGAAudioPlayer
import Testing

/// Covers the hand-over between the player's observers and the engine's
/// publishers, which the pure mapping tests cannot see: an observation is raised
/// on one turn and acted on the next, so what the player holds can change in
/// between. Everything published is therefore sampled from the player at that
/// later point rather than carried over from the observation.
@MainActor
@Suite("PlaybackEngine status observation")
struct PlaybackEngineObservationTests {
    /// `unloadCurrentItem()` pauses while the outgoing item is still attached, so
    /// the pause is observed as a held track and only acted on afterwards — by
    /// which point the engine is empty and has already reported `.idle`.
    @Test("an observation raised before the item was detached does not resurrect it")
    func observationAfterUnloadReadsIdle() throws {
        let engine = PlaybackEngine(notificationCenter: NotificationCenter())
        var statuses: [PlaybackStatus] = []
        let cancellable = engine.playbackStatusPublisher.sink { statuses.append($0) }

        engine.play(url: try Self.silentWav(seconds: 5))
        engine.unloadCurrentItem()
        engine.publishCurrentStatus()

        #expect(statuses.last == .idle, "an empty engine must not read as a paused track")
        cancellable.cancel()
    }

    /// `durationObservation.invalidate()` only stops callbacks that have not fired
    /// yet; one already on its way would otherwise report the previous track's
    /// length — which the player UI reads as the new track being ready.
    @Test("a duration observation raised for the previous track reports the new one")
    func durationObservationAfterTrackChangeReadsTheNewItem() async throws {
        let engine = PlaybackEngine(notificationCenter: NotificationCenter())
        engine.play(url: try Self.silentWav(seconds: 5))
        #expect(await poll { engine.duration } == 5, "the first track's own duration")

        engine.play(url: try Self.silentWav(seconds: 3))
        engine.publishCurrentDuration()

        #expect(engine.duration != 5, "the outgoing track's length must not land on its successor")
        #expect(await poll { engine.duration } == 3, "and the incoming track reports its own")
    }

    // MARK: - Real observations

    /// The tests above act on the publishing step directly. These two drive the
    /// real KVO callbacks end to end, which is the only way to catch an observer
    /// that never delivers at all.
    @Test("a loaded item publishes its own duration through the real observation")
    func loadedItemPublishesItsDuration() async throws {
        let engine = PlaybackEngine(notificationCenter: NotificationCenter())

        engine.play(url: try Self.silentWav(seconds: 5))

        #expect(await poll { engine.duration } == 5)
    }

    /// The player is already paused, so loading without starting changes nothing the
    /// status observation would report — the engine has to publish `.paused` itself, or
    /// it stays on `.loading` and the player shows a throbber that never goes away.
    @Test("an item loaded without autoplay reads as paused, still gets its duration, and does not start")
    func itemLoadedWithoutAutoplayReadsPaused() async throws {
        let engine = PlaybackEngine(notificationCenter: NotificationCenter())

        engine.play(url: try Self.silentWav(seconds: 5), autoplay: false)

        #expect(engine.currentStatusForTesting == .paused)
        #expect(!engine.isPlaybackIntended)
        #expect(await poll { engine.duration } == 5)
        #expect(engine.currentStatusForTesting == .paused, "loading the item must not start it")
        #expect(engine.currentTime == 0)
    }

    /// A replaced track, paused, is unloaded while its new file resolves; a play tapped in
    /// that gap already sets the player going, so the item plays — and has to be meant to,
    /// or an interruption that ends would leave it silent.
    @Test("a play asked for while nothing was loaded starts an item loaded without autoplay, as intended")
    func playAskedForBeforeLoadStartsTheItem() async throws {
        let engine = PlaybackEngine(notificationCenter: NotificationCenter())
        engine.unloadCurrentItem()
        engine.togglePlayPause()

        engine.play(url: try Self.silentWav(seconds: 5), autoplay: false)

        #expect(engine.isPlaybackIntended, "resumes after an interruption")
        let status = await poll { engine.currentStatusForTesting == .playing ? PlaybackStatus.playing : nil }
        #expect(status == .playing)
    }

    @Test("a loaded item reports playing through the real observation")
    func loadedItemReportsItsStatus() async throws {
        let engine = PlaybackEngine(notificationCenter: NotificationCenter())

        engine.play(url: try Self.silentWav(seconds: 5))

        // Playing rather than "anything but `.loading`": the player passes through
        // `.buffering` on its way to the first frame.
        let status = await poll { engine.currentStatusForTesting == .playing ? PlaybackStatus.playing : nil }
        #expect(status == .playing)
    }

    // MARK: - Helpers

    /// Re-reads `value` until it produces something, so the test spends only as
    /// long as the player actually needs rather than a fixed sleep.
    private func poll<T>(_ value: () -> T?, timeout: Duration = .seconds(5)) async -> T? {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if let value = value() { return value }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return value()
    }

    /// A playable local file of a known length: 8 kHz 8-bit silence in a WAV
    /// container, which AVPlayer reaches `.playing` on within a few hundred ms.
    private static func silentWav(seconds: Int) throws -> URL {
        let sampleRate = 8000
        let samples = [UInt8](repeating: 128, count: sampleRate * seconds)
        var data = Data()
        func append(_ string: String) { data.append(contentsOf: Array(string.utf8)) }
        func append32(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        append("RIFF"); append32(UInt32(36 + samples.count)); append("WAVE")
        append("fmt "); append32(16); append16(1); append16(1)
        append32(UInt32(sampleRate)); append32(UInt32(sampleRate)); append16(1); append16(8)
        append("data"); append32(UInt32(samples.count)); data.append(contentsOf: samples)

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("playback-engine-\(seconds)s.wav")
        try data.write(to: url)
        return url
    }
}
