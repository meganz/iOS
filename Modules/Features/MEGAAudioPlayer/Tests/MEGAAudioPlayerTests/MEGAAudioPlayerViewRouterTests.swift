import Foundation
@testable import MEGAAudioPlayer
import MEGADomainMock
import Testing
import UIKit

@MainActor
struct MEGAAudioPlayerViewRouterTests {
    @Test func startWithoutActiveSession_presentsFullScreenPlayer() {
        let (sut, presenter, engine, _) = makeSUT()

        sut.start(source: source(1))

        #expect(presenter.presentedCount == 1)
        #expect(engine.playedURLs == [track(1)])
    }

    /// IOS-12324: the tapped track takes over the running session — and the mini
    /// player with it — instead of covering the current screen.
    @Test func startWhileSessionIsActive_playsNewTrackWithoutPresenting() {
        let (sut, presenter, engine, service) = makeSUT()
        service.play(source: source(1))

        sut.start(source: source(2))

        #expect(presenter.presentedCount == 0)
        #expect(engine.playedURLs == [track(1), track(2)])
    }

    @Test func startWithCurrentlyPlayingTrackWhileSessionIsActive_doesNotPresent() {
        let (sut, presenter, engine, service) = makeSUT()
        service.play(source: source(1))

        sut.start(source: source(1))

        #expect(presenter.presentedCount == 0)
        #expect(engine.playedURLs == [track(1)], "the same track must not restart")
    }

    @Test func startAfterSessionStopped_presentsFullScreenPlayerAgain() {
        let (sut, presenter, engine, service) = makeSUT()
        service.play(source: source(1))
        service.stop()

        sut.start(source: source(2))

        #expect(presenter.presentedCount == 1)
        #expect(engine.playedURLs == [track(1), track(2)])
    }

    @Test func showCurrentWhileSessionIsActive_presentsFullScreenPlayer() {
        let (sut, presenter, engine, service) = makeSUT()
        service.play(source: source(1))

        sut.showCurrent()

        #expect(presenter.presentedCount == 1)
        #expect(engine.playedURLs == [track(1)], "expanding must not touch playback")
    }

    // MARK: - Helpers

    private func makeSUT() -> (
        sut: MEGAAudioPlayerViewRouter,
        presenter: SpyPresenterViewController,
        engine: MockPlaybackEngine,
        service: AudioPlaybackService
    ) {
        let engine = MockPlaybackEngine()
        let service = AudioPlaybackService(
            urlResolutionUseCase: OfflinePassthroughURLResolver(),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
        let presenter = SpyPresenterViewController()
        let sut = MEGAAudioPlayerViewRouter(
            presenter: presenter,
            service: service,
            accountUseCase: MockAccountUseCase()
        )
        return (sut, presenter, engine, service)
    }

    private func source(_ index: Int) -> PlaybackSource {
        .offlineFiles(file: track(index), queue: [track(index)])
    }

    private func track(_ index: Int) -> URL {
        URL(fileURLWithPath: "/tmp/track\(index).mp3")
    }
}

@MainActor
private final class SpyPresenterViewController: UIViewController {
    private(set) var presentedCount = 0

    override func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentedCount += 1
    }
}
