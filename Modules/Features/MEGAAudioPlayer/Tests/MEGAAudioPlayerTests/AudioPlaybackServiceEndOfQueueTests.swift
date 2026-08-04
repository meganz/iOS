import Foundation
@testable import MEGAAudioPlayer
import Testing

@MainActor
struct AudioPlaybackServiceEndOfQueueTests {
    @Test func queueFinishesWithRepeatOff_staysAtEndOfLastTrack() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        // Mid-queue: finishing track 1 advances to track 2 as usual.
        engine.finishCurrentTrack()
        #expect(engine.playedURLs == [track(1), track(2)])

        // Last track: playback just stops where it ended.
        engine.finishCurrentTrack()

        #expect(engine.currentTime == engine.itemDuration, "playhead stays at the end")
        #expect(engine.seekedSeconds.isEmpty, "nothing rewound it to 0")
        #expect(sut.currentQueue.currentIndex == 1, "repeat off must not wrap to the first track")
        #expect(engine.playedURLs == [track(1), track(2)], "no track was started")
    }

    @Test func playAfterQueueFinished_restartsFromFirstTrack() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        engine.finishCurrentTrack()
        engine.finishCurrentTrack()
        sut.togglePlayPause()

        #expect(engine.playedURLs == [track(1), track(2), track(1)])
        #expect(sut.currentQueue.currentIndex == 0)
        #expect(engine.togglePlayPauseCallCount == 0, "must not resume the track that just ended")
    }

    @Test func playAfterSingleTrackQueueFinished_restartsSameTrack() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))

        engine.finishCurrentTrack()
        sut.togglePlayPause()

        #expect(engine.playedURLs == [track(1), track(1)])
        #expect(engine.togglePlayPauseCallCount == 0)
        #expect(engine.pauseCallCount == 0, "the engine already stops itself at the end")
    }

    @Test func pauseTapWhileLastTrackRunsOut_pausesInsteadOfRestarting() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        engine.simulatePlayhead(at: engine.itemDuration)

        sut.togglePlayPause()

        #expect(engine.togglePlayPauseCallCount == 1)
        #expect(engine.playedURLs == [track(1)])
    }

    /// A track shorter than the end-of-track tolerance must not read as
    /// "finished" while the playhead is still at its start.
    @Test func playFromStartOfVeryShortLastTrack_resumesInsteadOfRestarting() {
        let engine = MockPlaybackEngine()
        engine.itemDuration = 0.05
        let sut = makeSUT(engine: engine)
        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))

        sut.togglePlayPause()
        sut.togglePlayPause()

        #expect(engine.togglePlayPauseCallCount == 2)
        #expect(engine.playedURLs == [track(1)])
    }

    @Test func togglePlayPauseMidQueue_forwardsToEngine() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.togglePlayPause()

        #expect(engine.togglePlayPauseCallCount == 1)
        #expect(engine.playedURLs == [track(1)])
    }

    @Test func playAfterQueueFinished_withRepeatEnabled_resumesCurrentTrack() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        engine.finishCurrentTrack()
        engine.finishCurrentTrack()
        sut.cycleRepeat()
        sut.cycleRepeat()
        #expect(sut.repeatMode == .one)

        sut.togglePlayPause()

        #expect(engine.togglePlayPauseCallCount == 1)
        #expect(engine.playedURLs == [track(1), track(2)])
    }

    @Test func seekAfterQueueFinished_playResumesCurrentTrack() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        engine.finishCurrentTrack()
        engine.finishCurrentTrack()
        sut.seek(toSeconds: 10)
        #expect(engine.currentTime == 10, "playhead moved off the end")

        sut.togglePlayPause()

        #expect(engine.togglePlayPauseCallCount == 1, "resumes the last track through the engine")
        #expect(sut.currentQueue.currentIndex == 1, "still on the last track")
        #expect(engine.playedURLs == [track(1), track(2)], "no track was (re)started")
    }

    // MARK: - Helpers

    private var twoTrackQueue: PlaybackSource {
        .offlineFiles(file: track(1), queue: [track(1), track(2)])
    }

    private func track(_ index: Int) -> URL {
        URL(fileURLWithPath: "/tmp/track\(index).mp3")
    }

    private func makeSUT(engine: MockPlaybackEngine) -> AudioPlaybackService {
        AudioPlaybackService(
            urlResolutionUseCase: OfflinePassthroughURLResolver(),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}
