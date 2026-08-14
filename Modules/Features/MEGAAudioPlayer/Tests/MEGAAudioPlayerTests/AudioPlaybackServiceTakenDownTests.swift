import Combine
import Foundation
@testable import MEGAAudioPlayer
import Testing

@MainActor
struct AudioPlaybackServiceTakenDownTests {

    @Test("A taken-down track is never handed to the engine")
    func takenDownTrackDoesNotPlay() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(1)])
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { !blocks.reasons.isEmpty })

        #expect(engine.playedURLs.isEmpty)
    }

    @Test("A taken-down track reports the block instead of ending the session itself")
    func takenDownTrackKeepsSessionAlive() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(1)])
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { !blocks.reasons.isEmpty })

        #expect(blocks.reasons == [.takenDown])
        #expect(sut.currentSource != nil, "the alert owns the teardown, not the service")
        #expect(engine.stopCallCount == 0)
    }

    @Test("An available track still plays when another one in the queue is taken down")
    func availableTrackPlays() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(2)])

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { !engine.playedURLs.isEmpty })

        #expect(engine.playedURLs == [track(1)])
    }

    @Test("Skipping onto a taken-down track blocks that track, leaving the previous one played")
    func skippingOntoTakenDownTrackBlocks() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(2)])
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { !engine.playedURLs.isEmpty })
        sut.playNext()
        await wait(until: { !blocks.reasons.isEmpty })

        #expect(engine.playedURLs == [track(1)], "the blocked track was never started")
        #expect(blocks.reasons == [.takenDown])
    }

    @Test("The outgoing track goes quiet while the next one is being checked")
    func outgoingTrackStopsDuringCheck() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(2)])

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { engine.isItemLoaded })
        sut.playNext()

        #expect(!engine.isItemLoaded, "the previous track must not play on during the check")
        #expect(engine.currentTime == 0, "nor keep driving the scrubber")
    }

    @Test("A blocked track leaves nothing playing")
    func blockedTrackLeavesNothingPlaying() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(2)])
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { engine.isItemLoaded })
        sut.playNext()
        await wait(until: { !blocks.reasons.isEmpty })

        #expect(!engine.isItemLoaded)
    }

    @Test("Revisiting a blocked track stops the previous one even though the verdict is cached")
    func revisitingBlockedTrackStopsPlayback() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(2)])
        let blocks = BlockRecorder(sut)

        // First visit establishes the verdict, so the second one takes the
        // synchronous path — where nothing awaits and it would be easy to leave the
        // outgoing track playing.
        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { engine.isItemLoaded })
        sut.playNext()
        await wait(until: { !blocks.reasons.isEmpty })
        sut.playPrevious()
        await wait(until: { engine.isItemLoaded })

        sut.playNext()

        #expect(!engine.isItemLoaded, "the previous track must not play on")
        #expect(engine.currentTime == 0)
        #expect(engine.playedURLs.last == track(1), "the blocked track was never started")
    }

    @Test("A verdict that arrives after the user moved on is dropped")
    func staleVerdictIsIgnored() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(1)])
        let blocks = BlockRecorder(sut)

        // The check for track 1 is still in flight when track 2 takes over.
        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        sut.playNext()
        await wait(until: { !engine.playedURLs.isEmpty })

        #expect(engine.playedURLs == [track(2)])
        #expect(blocks.reasons.isEmpty, "the superseded track must not raise an alert")
    }

    @Test("A subscriber that arrives after the block still learns about it")
    func blockIsLatchedForLateSubscribers() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(1)])
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { !blocks.reasons.isEmpty })

        // Stands in for the full-screen player being opened only after the block —
        // while just the mini player was showing there was nobody to alert.
        // A `CurrentValueSubject` hands its current value to a new subscriber
        // synchronously, so there is nothing to wait for here.
        let late = BlockRecorder(sut)

        #expect(late.reasons == [.takenDown])
    }

    @Test("Ending the session clears the block, so a later screen does not re-alert")
    func stopClearsTheBlock() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(1)])
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { !blocks.reasons.isEmpty })
        sut.stop()

        let late = BlockRecorder(sut)

        #expect(late.reasons.isEmpty)
    }

    @Test("Skipping off a blocked track onto a playable one clears the block")
    func movingToAnotherTrackClearsTheBlock() async {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, takenDown: [track(2)])
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2), track(3)]))
        await wait(until: { engine.isItemLoaded })
        sut.playNext()
        await wait(until: { !blocks.reasons.isEmpty })
        sut.playNext()
        await wait(until: { engine.playedURLs.last == track(3) })

        // Stands in for expanding the mini player back to the full-screen player: it
        // must not be told about a block that no longer applies.
        let late = BlockRecorder(sut)

        #expect(late.reasons.isEmpty)
    }

    @Test("Starting a new source clears an unacknowledged block")
    func newSourceClearsTheBlock() async {
        let engine = MockPlaybackEngine()
        let resolver = StubTakenDownTrackResolver(takenDown: [track(1)])
        let sut = makeSUT(engine: engine, resolver: resolver)
        let blocks = BlockRecorder(sut)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { !blocks.reasons.isEmpty })
        sut.play(source: .offlineFiles(file: track(2), queue: [track(2)]))

        let late = BlockRecorder(sut)

        #expect(late.reasons.isEmpty, "a new queue must not inherit the previous block")
    }

    @Test("Starting a new source clears the previous session's takedown verdicts")
    func newSourceResetsResolver() async {
        let engine = MockPlaybackEngine()
        let resolver = PassthroughTrackResolver()
        let sut = makeSUT(engine: engine, resolver: resolver)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        sut.play(source: .offlineFiles(file: track(2), queue: [track(2)]))

        #expect(resolver.resetCallCount == 2, "verdicts must not outlive the queue they were taken for")
    }

    @Test("Stopping clears the session's takedown verdicts")
    func stopResetsResolver() async {
        let engine = MockPlaybackEngine()
        let resolver = PassthroughTrackResolver()
        let sut = makeSUT(engine: engine, resolver: resolver)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        let afterPlay = resolver.resetCallCount
        sut.stop()

        #expect(resolver.resetCallCount == afterPlay + 1)
    }

    // MARK: - Helpers

    private func track(_ index: Int) -> URL {
        URL(fileURLWithPath: "/tmp/track\(index).mp3")
    }

    /// Yields until `condition` holds. Waiting on the outcome itself keeps the
    /// test independent of how many scheduler turns the resolution task needs;
    /// the cap only exists so a genuine regression fails instead of hanging.
    private func wait(
        until condition: () -> Bool,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        for _ in 0..<1000 {
            if condition() { return }
            await Task.yield()
        }
        Issue.record("Timed out waiting for the expected state", sourceLocation: sourceLocation)
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        takenDown: [URL]
    ) -> AudioPlaybackService {
        makeSUT(engine: engine, resolver: StubTakenDownTrackResolver(takenDown: takenDown))
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        resolver: some AudioTrackResolutionUseCaseProtocol
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: resolver,
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}

/// Collects everything the service reports on `playbackBlockedPublisher`, and
/// keeps the subscription alive for as long as the test holds it. The replayed
/// `nil` that every subscriber receives up front is dropped, so `reasons` holds
/// only the blocks that actually happened.
@MainActor
private final class BlockRecorder {
    private(set) var reasons: [PlaybackBlockedReason] = []
    private var cancellable: AnyCancellable?

    init(_ service: some PlaybackStateObservable) {
        cancellable = service.playbackBlockedPublisher
            .compactMap { $0 }
            .sink { [weak self] in
                self?.reasons.append($0)
            }
    }
}
