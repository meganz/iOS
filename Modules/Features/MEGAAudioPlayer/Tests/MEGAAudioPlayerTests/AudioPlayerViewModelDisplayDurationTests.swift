import Foundation
@testable import MEGAAudioPlayer
import Testing

/// `displayDuration` shows the player's duration, falling back to the one read from the file
/// while the item loads. Driven through a real `AudioPlaybackService`, which clears the file's
/// duration when a track starts or playback stops.
@MainActor
struct AudioPlayerViewModelDisplayDurationTests {

    @Test("Shows the file's duration while the player has none")
    func fallsBackToTheFileDuration() async {
        let engine = MockPlaybackEngine()
        engine.withholdsDuration = true
        let service = makeService(engine: engine, metadata: [track(1): AudioMetadata(duration: 295)])
        let vm = AudioPlayerViewModel(service: service)

        service.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { vm.displayDuration == 295 })

        #expect(vm.duration == nil, "the scrubber still waits for the player")
    }

    @Test("Switches to the player's duration once the item reports one")
    func switchesToThePlayerDuration() async {
        let engine = MockPlaybackEngine()
        engine.withholdsDuration = true
        engine.itemDuration = 294.7
        let service = makeService(engine: engine, metadata: [track(1): AudioMetadata(duration: 295)])
        let vm = AudioPlayerViewModel(service: service)

        service.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { vm.displayDuration == 295 })
        engine.simulateDurationReady()
        await wait(until: { vm.displayDuration == 294.7 })

        #expect(vm.displayDuration == vm.duration)
    }

    @Test("Keeps the player's duration when the file's arrives after it")
    func keepsThePlayerDurationOverALaterFileDuration() async {
        let engine = MockPlaybackEngine()
        engine.itemDuration = 294.7
        let service = makeService(
            engine: engine,
            metadata: [track(1): AudioMetadata(artist: "Artist", duration: 295)]
        )
        let vm = AudioPlayerViewModel(service: service)

        service.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { vm.artist == "Artist" })

        #expect(vm.displayDuration == 294.7)
    }

    @Test("Clears the file's duration when the next track starts")
    func clearsTheFileDurationOnTrackChange() async {
        let engine = MockPlaybackEngine()
        engine.withholdsDuration = true
        let service = makeService(engine: engine, metadata: [track(1): AudioMetadata(duration: 295)])
        let vm = AudioPlayerViewModel(service: service)

        service.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { vm.displayDuration == 295 })
        service.playNext()
        await wait(until: { vm.currentTrackID == track(2).path })

        #expect(vm.displayDuration == nil, "track 2 has no duration of its own yet")
    }

    @Test("Clears the file's duration when playback stops")
    func clearsTheFileDurationOnStop() async {
        let engine = MockPlaybackEngine()
        engine.withholdsDuration = true
        let service = makeService(engine: engine, metadata: [track(1): AudioMetadata(duration: 295)])
        let vm = AudioPlayerViewModel(service: service)

        service.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { vm.displayDuration == 295 })
        service.stop()
        await wait(until: { vm.displayDuration == nil })

        #expect(vm.displayDuration == nil)
    }

    // MARK: - Helpers

    private func track(_ index: Int) -> URL {
        URL(fileURLWithPath: "/tmp/track\(index).mp3")
    }

    private func makeService(engine: MockPlaybackEngine, metadata: [URL: AudioMetadata]) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: FixedAudioMetadataCache(metadata),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}
