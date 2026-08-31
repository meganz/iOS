import Foundation
@testable import MEGAAudioPlayer
import Testing

/// The taken-down alert and the rule the view model applies when it is
/// acknowledged. Driven through a real `AudioPlaybackService` because the bug
/// lives in the hand-off between the two: what dismissing the alert does to the
/// queue, and whether the screen closes.
@MainActor
struct AudioPlayerViewModelTakenDownTests {

    @Test("Reaching a taken-down track raises the alert")
    func blockRaisesTheAlert() async {
        let engine = MockPlaybackEngine()
        let service = makeService(engine: engine, takenDown: [track(2)])
        let vm = AudioPlayerViewModel(service: service)

        service.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { engine.isItemLoaded })
        service.playNext()
        await wait(until: { vm.isTakenDownAlertPresented })

        #expect(vm.isTakenDownAlertPresented)
    }

    @Test("Dismissing the alert keeps the player open and moves on to the next track")
    func dismissingTheAlertKeepsThePlayerOpen() async {
        let engine = MockPlaybackEngine()
        let service = makeService(engine: engine, takenDown: [track(2)])
        let vm = AudioPlayerViewModel(service: service)
        let dismissals = DismissRecorder()
        vm.onDismiss = { dismissals.record() }

        service.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2), track(3)]))
        await wait(until: { engine.isItemLoaded })
        service.playNext()
        await wait(until: { vm.isTakenDownAlertPresented })

        vm.confirmTakenDownAlert()
        // The queue moves on synchronously, but the next track only reaches the
        // engine once its admission check comes back — so wait on the slower one.
        await wait(until: { engine.playedURLs.last == track(3) })
        await wait(until: { vm.currentTrackID == track(3).path })

        #expect(!vm.isTakenDownAlertPresented)
        #expect(dismissals.count == 0, "the player must stay open")
    }

    @Test("Dismissing the alert takes the unavailable track out of the playlist")
    func dismissingTheAlertRemovesTheTrackFromThePlaylist() async {
        let engine = MockPlaybackEngine()
        let service = makeService(engine: engine, takenDown: [track(2)])
        let vm = AudioPlayerViewModel(service: service)

        service.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2), track(3)]))
        await wait(until: { engine.isItemLoaded })
        service.playNext()
        await wait(until: { vm.isTakenDownAlertPresented })

        vm.confirmTakenDownAlert()
        await wait(until: { vm.playlistItems.count == 2 })

        #expect(vm.playlistItems.map(\.id) == [track(1).path, track(3).path])
    }

    @Test("Dismissing the alert on the last track wraps to the start rather than closing")
    func dismissingTheAlertOnTheLastTrackWraps() async {
        let engine = MockPlaybackEngine()
        let service = makeService(engine: engine, takenDown: [track(2)])
        let vm = AudioPlayerViewModel(service: service)
        let dismissals = DismissRecorder()
        vm.onDismiss = { dismissals.record() }

        service.play(source: .offlineFiles(file: track(1), queue: [track(1), track(2)]))
        await wait(until: { engine.isItemLoaded })
        service.playNext()
        await wait(until: { vm.isTakenDownAlertPresented })

        vm.confirmTakenDownAlert()
        await wait(until: { engine.playedURLs.count == 2 })
        await wait(until: { vm.playlistItems.count == 1 })

        #expect(engine.playedURLs == [track(1), track(1)])
        #expect(vm.playlistItems.map(\.id) == [track(1).path])
        #expect(dismissals.count == 0, "the player must stay open")
    }

    @Test("Dismissing the alert closes the player when the unavailable track is the only one queued")
    func dismissingTheAlertClosesThePlayerOnASingleTrackQueue() async {
        let engine = MockPlaybackEngine()
        let service = makeService(engine: engine, takenDown: [track(1)])
        let vm = AudioPlayerViewModel(service: service)
        let dismissals = DismissRecorder()
        vm.onDismiss = { dismissals.record() }

        service.play(source: .offlineFiles(file: track(1), queue: [track(1)]))
        await wait(until: { vm.isTakenDownAlertPresented })

        vm.confirmTakenDownAlert()
        await wait(until: { dismissals.count == 1 })

        #expect(service.currentSource == nil, "the session ended")
    }

    // MARK: - Helpers

    private func track(_ index: Int) -> URL {
        URL(fileURLWithPath: "/tmp/track\(index).mp3")
    }

    private func makeService(
        engine: MockPlaybackEngine,
        takenDown: [URL]
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: StubTakenDownTrackResolver(takenDown: takenDown),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}

/// Counts the router-side dismissals the view model asks for.
@MainActor
private final class DismissRecorder {
    private(set) var count = 0

    func record() { count += 1 }
}
