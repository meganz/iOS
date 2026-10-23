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

    // MARK: - Dismissing while logged out

    /// CC-8883: the folder link's docked mini player takes playback over once the full screen player closes.
    @Test func dismissWhileLoggedOut_playingFromFolderLink_keepsPlaying() {
        let (sut, presenter, _, service) = makeSUT(isLoggedIn: false)
        let node = StubPlayableNode(handle: 1, name: "song1.mp3", fingerprint: "fingerprint-1")
        sut.start(source: .folderLink(node: node, queue: [node]))

        presenter.presentedHost?.onDismiss?()

        #expect(service.currentSource != nil)
    }

    @Test func dismissWhileLoggedOut_playingFromElsewhere_stopsPlayback() {
        let (sut, presenter, _, service) = makeSUT(isLoggedIn: false)
        sut.start(source: source(1))

        presenter.presentedHost?.onDismiss?()

        #expect(service.currentSource == nil, "nothing would be left to control it")
    }

    @Test func dismissWhileLoggedIn_keepsPlaying() {
        let (sut, presenter, _, service) = makeSUT(isLoggedIn: true)
        sut.start(source: source(1))

        presenter.presentedHost?.onDismiss?()

        #expect(service.currentSource != nil)
    }

    // MARK: - Helpers

    private func makeSUT(isLoggedIn: Bool = true) -> (
        sut: MEGAAudioPlayerViewRouter,
        presenter: SpyPresenterViewController,
        engine: MockPlaybackEngine,
        service: AudioPlaybackService
    ) {
        let engine = MockPlaybackEngine()
        let service = AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(),
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
            accountUseCase: MockAccountUseCase(isLoggedIn: isLoggedIn)
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
    private(set) var presentedHost: AudioPlayerHostingController?

    override func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentedCount += 1
        presentedHost = viewControllerToPresent as? AudioPlayerHostingController
    }
}
