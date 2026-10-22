import Foundation
@testable import MEGAAudioPlayer
import Testing

@MainActor
struct AudioPlaybackServiceInterruptionTests {
    @Test func beginWhilePlaying_pausesAndEndResumes() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        #expect(engine.pauseCallCount == 1)
        #expect(sut.status == .paused)

        sut.endInterruption(shouldResume: true)
        #expect(engine.togglePlayPauseCallCount == 1)
        #expect(sut.status == .playing)
    }

    @Test func endWithoutShouldResume_staysPaused() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        sut.endInterruption(shouldResume: false)

        #expect(engine.togglePlayPauseCallCount == 0)
        #expect(sut.status == .paused)
    }

    @Test func beginWhilePaused_leavesItPausedAfterEnd() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)
        sut.togglePlayPause()
        #expect(sut.status == .paused)

        sut.beginInterruption()
        sut.endInterruption(shouldResume: true)

        #expect(engine.pauseCallCount == 0, "nothing to pause")
        #expect(engine.togglePlayPauseCallCount == 1, "only the listener's own pause")
        #expect(sut.status == .paused)
    }

    @Test func playTappedDuringInterruption_isNotToggledAgainOnEnd() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        sut.togglePlayPause()
        sut.endInterruption(shouldResume: true)

        #expect(engine.togglePlayPauseCallCount == 1)
        #expect(sut.status == .playing)
    }

    @Test func playThenPauseTappedDuringInterruption_staysPausedOnEnd() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        sut.togglePlayPause()
        sut.togglePlayPause()
        sut.endInterruption(shouldResume: true)

        #expect(engine.togglePlayPauseCallCount == 2, "only the listener's own toggles")
        #expect(sut.status == .paused)
    }

    @Test func sourceStartedByUserDuringInterruption_playsRightAwayAndIsLeftAloneOnEnd() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)
        sut.beginInterruption()

        sut.play(source: .offlineFiles(file: track(3), queue: [track(3)]))
        #expect(engine.playedURLs.last == track(3))
        #expect(engine.loadedPausedURLs.isEmpty, "the user asked for it, so it does not wait")
        #expect(sut.status == .playing)

        sut.endInterruption(shouldResume: true)
        #expect(engine.togglePlayPauseCallCount == 0)
        #expect(sut.status == .playing)
    }

    @Test func trackEndingAfterUserTookOver_movesOnWithoutWaiting() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)
        sut.beginInterruption()

        sut.togglePlayPause()
        engine.finishCurrentTrack()
        await wait(until: { engine.playedURLs.last == track(2) })

        #expect(engine.loadedPausedURLs.isEmpty, "once the user plays it, the queue moves on as usual")
        #expect(sut.status == .playing)
    }

    @Test func stopDuringInterruption_doesNotResumeOnEnd() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        sut.stop()
        sut.endInterruption(shouldResume: true)

        #expect(engine.togglePlayPauseCallCount == 0)
        #expect(sut.status == .idle)
    }

    @Test func trackFinishingLoadingDuringInterruption_loadsPausedAndPlaysOnEnd() async {
        let engine = MockPlaybackEngine()
        // Resolves only after a suspension, so the track is still loading as the interruption begins
        let sut = makeSUT(engine: engine, trackResolver: StubTakenDownTrackResolver(takenDown: []))
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        await wait(until: { !engine.playedURLs.isEmpty })
        #expect(engine.loadedPausedURLs == [track(1)], "must not play over the other player")

        sut.endInterruption(shouldResume: true)
        #expect(sut.status == .playing)
    }

    @Test func trackPickedByUserDuringInterruption_playsRightAway() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)
        sut.beginInterruption()

        sut.play(atIndex: 1)
        #expect(engine.playedURLs.last == track(2))
        #expect(engine.loadedPausedURLs.isEmpty, "the user asked for it, so it does not wait")

        sut.endInterruption(shouldResume: true)
        #expect(engine.togglePlayPauseCallCount == 0)
        #expect(sut.status == .playing)
    }

    @Test func nextOrPreviousTappedDuringInterruption_playsRightAway() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)
        sut.beginInterruption()

        sut.playNext()
        #expect(engine.playedURLs.last == track(2))
        sut.playPrevious()
        #expect(engine.playedURLs.last == track(1))

        #expect(engine.loadedPausedURLs.isEmpty)
        #expect(sut.status == .playing)
    }

    @Test func overlappingInterruptions_resumeOnlyWhenTheLastOneEnds() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        sut.beginInterruption()
        #expect(engine.pauseCallCount == 1)

        sut.endInterruption(shouldResume: true)
        #expect(engine.togglePlayPauseCallCount == 0, "another player still owns playback")
        #expect(sut.status == .paused)

        sut.endInterruption(shouldResume: true)
        #expect(engine.togglePlayPauseCallCount == 1)
        #expect(sut.status == .playing)
    }

    @Test func resetAfterStop_dropsAnInterruptionThatNeverEnded() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        sut.stop()
        sut.resetInterruption()
        sut.play(source: twoTrackQueue)

        #expect(engine.playedURLs == [track(1), track(1)], "the next session plays right away")
        #expect(engine.loadedPausedURLs.isEmpty)

        sut.endInterruption(shouldResume: true)
        #expect(engine.togglePlayPauseCallCount == 0, "a late end from the gone player is ignored")
    }

    @Test func extraEnd_afterTheLastOne_doesNothing() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)

        sut.beginInterruption()
        sut.endInterruption(shouldResume: true)
        sut.endInterruption(shouldResume: true)
        sut.beginInterruption()

        #expect(engine.pauseCallCount == 2, "the next begin still steps back")
        #expect(sut.status == .paused)
    }

    @Test func endWithoutBegin_doesNothing() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: twoTrackQueue)
        sut.togglePlayPause()

        sut.endInterruption(shouldResume: true)

        #expect(engine.togglePlayPauseCallCount == 1)
        #expect(sut.status == .paused)
    }

    // MARK: - Helpers

    private var twoTrackQueue: PlaybackSource {
        .offlineFiles(file: track(1), queue: [track(1), track(2)])
    }

    private func track(_ index: Int) -> URL {
        URL(fileURLWithPath: "/tmp/track\(index).mp3")
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        trackResolver: some AudioTrackResolutionUseCaseProtocol = PassthroughTrackResolver()
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: trackResolver,
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}
