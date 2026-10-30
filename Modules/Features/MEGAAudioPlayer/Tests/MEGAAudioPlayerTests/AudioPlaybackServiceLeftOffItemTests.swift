import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import Testing

/// `stop()` asks the continuation use case what became of the position, then mirrors that
/// into the continue-where-you-left-off store.
@MainActor
struct AudioPlaybackServiceLeftOffItemTests {

    @Test("A saved position records the track")
    func stop_whenPositionIsSaved_shouldRecordLeftOffItem() async {
        let engine = MockPlaybackEngine()
        engine.itemDuration = resumableDuration
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(engine: engine, outcome: .saved, recordUseCase: recordUseCase)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.map(\.handle) == [1])
        #expect(recordUseCase.record_Calls.map(\.name) == ["song1.mp3"])
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test("A discarded position removes the track")
    func stop_whenPositionIsRemoved_shouldRemoveLeftOffItem() async {
        let engine = MockPlaybackEngine()
        engine.itemDuration = resumableDuration
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(engine: engine, outcome: .removed, recordUseCase: recordUseCase)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.remove_Calls == [1])
        #expect(recordUseCase.record_Calls.isEmpty)
    }

    @Test("A track too short to resume never reaches the store")
    func stop_whenTrackIsBelowResumableDuration_shouldNotTouchLeftOffItem() async {
        let engine = MockPlaybackEngine()
        engine.itemDuration = 60
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(engine: engine, outcome: .saved, recordUseCase: recordUseCase)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.isEmpty)
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test("An offline file has no handle, so there is nothing to store")
    func stop_whenPlayingAnOfflineFile_shouldNotTouchLeftOffItem() async {
        let engine = MockPlaybackEngine()
        engine.itemDuration = resumableDuration
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(engine: engine, outcome: .saved, recordUseCase: recordUseCase)
        let file = URL(fileURLWithPath: "/tmp/song1.mp3")
        sut.play(source: .offlineFiles(file: file, queue: [file]))

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.isEmpty)
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test("Stopping with nothing playing does not reach the store")
    func stop_whenNothingIsPlaying_shouldNotTouchLeftOffItem() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(engine: MockPlaybackEngine(), outcome: .saved, recordUseCase: recordUseCase)

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.isEmpty)
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    // MARK: - Helpers

    /// Longer than the service's own minimum, so a position is eligible to be kept.
    private let resumableDuration: TimeInterval = 10 * 60

    private func song(_ handle: UInt64) -> NodeEntity {
        NodeEntity(name: "song\(handle).mp3", fingerprint: "fingerprint-\(handle)", handle: handle)
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        outcome: PlaybackContinuationOutcomeEntity,
        recordUseCase: MockLeftOffItemRecordUseCase
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(urlUseCase: StreamURLResolver()),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: FixedOutcomeContinuationUseCase(outcome: outcome),
            leftOffItemRecordUseCase: recordUseCase
        )
    }
}

private struct FixedOutcomeContinuationUseCase: PlaybackContinuationUseCaseProtocol {
    let outcome: PlaybackContinuationOutcomeEntity

    func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        .startFromBeginning
    }

    func savedPlaybackTime(for fingerprint: FingerprintEntity) -> TimeInterval? { nil }

    func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {}

    @discardableResult
    func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) -> PlaybackContinuationOutcomeEntity {
        outcome
    }

    func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity) {}
}

private struct StreamURLResolver: AudioTrackURLUseCaseProtocol {
    func url(for track: PlaybackTrack) -> URL? {
        switch track {
        case .account(let node):
            return URL(string: "https://stream.test/\(node.handle)")
        case .folderLink(let node):
            return URL(string: "https://stream.test/\(node.handle)")
        case .offlineNode(_, let file), .offline(let file):
            return file
        case .fileLink:
            return nil
        }
    }
}
