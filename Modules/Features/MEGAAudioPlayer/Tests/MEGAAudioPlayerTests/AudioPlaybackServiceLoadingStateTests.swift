import Combine
import Foundation
@testable import MEGAAudioPlayer
import Testing

/// Covers the state *sequence* the view models derive from the service, which the
/// per-value mapping tests cannot see: `status` and `hasStartedPlayback` are two
/// separate publishers, so the order the service sends them in is observable.
@MainActor
struct AudioPlaybackServiceLoadingStateTests {
    @Test("reaching the first frame does not flash the mid-track stall state")
    func firstFrameGoesStraightFromReadyToPlaying() {
        let engine = MockPlaybackEngine()
        engine.stallsBeforeFirstFrame = true
        let sut = makeSUT(engine: engine)
        let recorder = recordLoadingStates(of: sut)

        sut.play(source: singleTrackQueue)
        engine.simulateFirstFrame()

        #expect(recorder.states == [.loading, .ready, .playing])
    }

    @Test("a stall part-way through a track reads as the mid-track stall state")
    func stallAfterTheFirstFrameIsBuffering() {
        let engine = MockPlaybackEngine()
        engine.stallsBeforeFirstFrame = true
        let sut = makeSUT(engine: engine)
        let recorder = recordLoadingStates(of: sut)

        sut.play(source: singleTrackQueue)
        engine.simulateFirstFrame()
        engine.simulateStall()
        engine.simulateFirstFrame()

        #expect(recorder.states == [.loading, .ready, .playing, .buffering, .playing])
    }

    /// The metadata parse can outlive the first frame — a remote track whose tags
    /// are still loading is already audible, so its controls have to work.
    @Test("a track playing before its metadata lands is playable, not loading")
    func playbackBeforeMetadataIsPlaying() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine, metadataCache: NeverResolvingAudioMetadataCache())
        let recorder = recordLoadingStates(of: sut, isReady: false)

        sut.play(source: singleTrackQueue)

        #expect(sut.artworkResolved == false, "the parse is still pending")
        #expect(recorder.states.last == .playing)
        #expect(recorder.states.last?.isToggleEnabled == true, "the user must be able to pause what they can hear")
    }

    // MARK: - Helpers

    /// Mirrors the view models' pipeline, with readiness pinned to `true` so the
    /// sequence under test is the status/latch interleaving alone.
    @MainActor
    private final class LoadingStateRecorder {
        private(set) var states: [PlayerLoadingState] = []
        private var cancellable: AnyCancellable?

        init(service: some PlaybackStateObservable, isReady: Bool) {
            cancellable = Publishers.CombineLatest(
                service.statusPublisher,
                service.hasStartedPlaybackPublisher
            )
            .map { status, hasStartedPlayback in
                PlayerLoadingState(status: status, hasStartedPlayback: hasStartedPlayback, isReady: isReady)
            }
            .removeDuplicates()
            .sink { [weak self] in self?.states.append($0) }
        }
    }

    private func recordLoadingStates(
        of service: some PlaybackStateObservable,
        isReady: Bool = true
    ) -> LoadingStateRecorder {
        LoadingStateRecorder(service: service, isReady: isReady)
    }

    private var singleTrackQueue: PlaybackSource {
        .offlineFiles(file: track, queue: [track])
    }

    private var track: URL {
        URL(fileURLWithPath: "/tmp/track1.mp3")
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        metadataCache: some AudioMetadataCacheProtocol = StubAudioMetadataCache()
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: metadataCache,
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}
