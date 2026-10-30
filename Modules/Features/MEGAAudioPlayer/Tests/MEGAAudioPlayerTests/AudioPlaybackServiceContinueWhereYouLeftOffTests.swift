import Combine
import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
struct AudioPlaybackServiceContinueWhereYouLeftOffTests {

    @Test("Opening from Continue where you left off resumes at the saved position with no prompt, even after Restart was chosen")
    func continueWhereYouLeftOff_resumesAtSavedPosition() async {
        let engine = MockPlaybackEngine()
        let useCase = MockPlaybackContinuationUseCase(status: .startFromBeginning)
        useCase._savedPlaybackTime = 120
        let sut = makeSUT(engine: engine, playbackContinuationUseCase: useCase)
        var prompt: ResumePrompt?
        let cancellable = sut.resumePromptPublisher.sink { prompt = $0 }

        sut.play(source: .continueWhereYouLeftOff(node: song(1)))

        await wait(until: { engine.seekedSeconds == [120] })
        #expect(engine.seekedSeconds == [120])
        #expect(prompt == nil)
        #expect(engine.pauseCallCount == 0)
        cancellable.cancel()
    }

    @Test("Opening from Continue where you left off with no saved position starts at the beginning with no prompt")
    func continueWhereYouLeftOff_withoutSavedPosition_startsAtBeginning() async {
        let engine = MockPlaybackEngine()
        let useCase = MockPlaybackContinuationUseCase(status: .displayDialog(playbackTime: 30))
        let sut = makeSUT(engine: engine, playbackContinuationUseCase: useCase)
        var prompt: ResumePrompt?
        let cancellable = sut.resumePromptPublisher.sink { prompt = $0 }

        sut.play(source: .continueWhereYouLeftOff(node: song(1)))

        await wait(until: { !engine.playedURLs.isEmpty })
        await settle()
        #expect(engine.seekedSeconds.isEmpty)
        #expect(prompt == nil)
        cancellable.cancel()
    }

    @Test("Opening from another place still follows the remembered Restart choice")
    func otherSource_followsRememberedChoice() async {
        let engine = MockPlaybackEngine()
        let useCase = MockPlaybackContinuationUseCase(status: .startFromBeginning)
        useCase._savedPlaybackTime = 120
        let sut = makeSUT(engine: engine, playbackContinuationUseCase: useCase)

        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        await wait(until: { !engine.playedURLs.isEmpty })
        await settle()
        #expect(engine.seekedSeconds.isEmpty)
    }

    @Test("Continue where you left off plays only the opened track")
    func continueWhereYouLeftOff_queueHasOneTrack() {
        let sut = makeSUT(engine: MockPlaybackEngine(), playbackContinuationUseCase: MockPlaybackContinuationUseCase())

        sut.play(source: .continueWhereYouLeftOff(node: song(1)))

        #expect(sut.currentQueue.tracks.map(\.id) == ["1"])
    }

    // MARK: - Helpers

    private func song(_ handle: UInt64) -> NodeEntity {
        NodeEntity(name: "song.mp3", fingerprint: "fingerprint-\(handle)", handle: handle)
    }

    private func settle() async {
        try? await Task.sleep(for: .milliseconds(50))
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(urlUseCase: StreamURLResolver()),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: playbackContinuationUseCase,
            audioNodeUpdatesUseCase: MockAudioNodeUpdatesUseCase()
        )
    }
}

private struct StreamURLResolver: AudioTrackURLUseCaseProtocol {
    func url(for track: PlaybackTrack) -> URL? {
        URL(string: "https://stream.test/\(track.id)")
    }
}
