import Foundation
@testable import MEGAAudioPlayer
import Testing

/// `removeTrack(withID:)` as a queue primitive: it edits the queue and re-anchors
/// the index, and never decides what plays.
///
/// Every track resolves from the cache path here, so playback reaches the engine
/// synchronously and there is nothing to wait on.
@MainActor
struct AudioPlaybackServiceRemoveTrackTests {

    @Test("Removing an upcoming track leaves the current one playing")
    func removingUpcomingTrackKeepsPlayback() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2), track(3)]))
        sut.removeTrack(withID: track(2).path)

        #expect(sut.currentQueue.tracks.map(\.id) == [track(1).path, track(3).path])
        #expect(sut.currentQueue.current?.id == track(1).path)
        #expect(engine.playedURLs == [track(1)], "nothing was restarted")
    }

    @Test("Removing an already-played track keeps the index on the current one")
    func removingPlayedTrackReanchorsTheIndex() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2), track(3)]))
        sut.playNext()
        sut.removeTrack(withID: track(1).path)

        #expect(sut.currentQueue.tracks.map(\.id) == [track(2).path, track(3).path])
        #expect(sut.currentQueue.currentIndex == 0)
        #expect(sut.currentQueue.current?.id == track(2).path)
        #expect(engine.playedURLs == [track(1), track(2)], "nothing was restarted")
    }

    @Test("The track playing right now is refused")
    func removingTheCurrentTrackIsRefused() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        sut.removeTrack(withID: track(1).path)

        #expect(sut.currentQueue.tracks.map(\.id) == [track(1).path, track(2).path])
    }

    @Test("An unknown id leaves the queue alone")
    func removingAnUnknownTrackIsANoOp() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        sut.removeTrack(withID: track(9).path)

        #expect(sut.currentQueue.tracks.map(\.id) == [track(1).path, track(2).path])
    }

    @Test("Turning shuffle off does not bring a removed track back")
    func unshufflingDoesNotRestoreARemovedTrack() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)

        sut.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2), track(3)]))
        // Shuffle reorders only the upcoming tracks, and from index 0 that is
        // tracks 2 and 3 — the removal has to reach the pre-shuffle order too.
        sut.toggleShuffle()
        sut.removeTrack(withID: track(2).path)

        sut.toggleShuffle()

        #expect(sut.currentQueue.tracks.map(\.id) == [track(1).path, track(3).path])
        #expect(sut.currentQueue.current?.id == track(1).path)
    }

    // MARK: - Helpers

    private func track(_ index: Int) -> URL {
        URL(fileURLWithPath: "/tmp/track\(index).mp3")
    }

    private func makeSUT(engine: MockPlaybackEngine) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}
