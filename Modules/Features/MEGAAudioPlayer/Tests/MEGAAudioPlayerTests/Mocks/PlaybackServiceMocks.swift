import Combine
import Foundation
@testable import MEGAAudioPlayer
import MEGADomain

@MainActor
final class MockPlaybackEngine: PlaybackEngineProtocol {
    private let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let durationSubject = CurrentValueSubject<TimeInterval?, Never>(nil)
    private let playbackStatusSubject = CurrentValueSubject<PlaybackStatus, Never>(.loading)
    private let playbackSpeedSubject = CurrentValueSubject<Float, Never>(1)
    private let playbackRateSubject = CurrentValueSubject<Float, Never>(0)
    private let didPlayToEndSubject = PassthroughSubject<Void, Never>()

    private(set) var playedURLs: [URL] = []
    private(set) var seekedSeconds: [TimeInterval] = []
    private(set) var togglePlayPauseCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var replayCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var unloadCallCount = 0

    /// `true` while an item is loaded — i.e. something can actually be heard.
    private(set) var isItemLoaded = false

    /// Duration reported for every item handed to `play(url:)`.
    var itemDuration: TimeInterval = 100

    var currentTime: TimeInterval { currentTimeSubject.value }
    var duration: TimeInterval? { durationSubject.value }

    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<TimeInterval?, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> {
        playbackStatusSubject.eraseToAnyPublisher()
    }

    var playbackSpeedPublisher: AnyPublisher<Float, Never> {
        playbackSpeedSubject.eraseToAnyPublisher()
    }

    var playbackRatePublisher: AnyPublisher<Float, Never> {
        playbackRateSubject.eraseToAnyPublisher()
    }

    var didPlayToEndPublisher: AnyPublisher<Void, Never> {
        didPlayToEndSubject.eraseToAnyPublisher()
    }

    func play(url: URL) {
        playedURLs.append(url)
        isItemLoaded = true
        currentTimeSubject.send(0)
        durationSubject.send(itemDuration)
        playbackStatusSubject.send(.playing)
    }

    func unloadCurrentItem() {
        unloadCallCount += 1
        isItemLoaded = false
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        playbackStatusSubject.send(.loading)
    }

    func togglePlayPause() {
        togglePlayPauseCallCount += 1
        playbackStatusSubject.send(playbackStatusSubject.value == .playing ? .paused : .playing)
    }

    func pause() {
        pauseCallCount += 1
        playbackStatusSubject.send(.paused)
    }

    func setPlaybackSpeed(_ rate: Float) {
        playbackSpeedSubject.send(rate)
    }

    func seek(toSeconds seconds: TimeInterval) {
        seekedSeconds.append(seconds)
        currentTimeSubject.send(seconds)
    }

    func replay() {
        replayCallCount += 1
        currentTimeSubject.send(0)
    }

    func stop() {
        stopCallCount += 1
    }

    // MARK: - Test drivers

    /// Play the current item out: the playhead lands on the end, the player
    /// stops itself, then `AVPlayerItem.didPlayToEndTimeNotification` fires.
    func finishCurrentTrack() {
        currentTimeSubject.send(durationSubject.value ?? 0)
        playbackStatusSubject.send(.paused)
        didPlayToEndSubject.send(())
    }

    /// Move the playhead without changing whether playback is running.
    func simulatePlayhead(at seconds: TimeInterval) {
        currentTimeSubject.send(seconds)
    }
}

struct StubAudioStreamingRepository: AudioStreamingRepositoryProtocol {
    static var newRepo: StubAudioStreamingRepository { StubAudioStreamingRepository() }

    var isServerRunning: Bool { true }

    func startServer() {}

    func stopServer() {}

    func streamingURL(for node: StreamingNode) -> URL? { nil }
}

struct StubPlaybackContinuationUseCase: PlaybackContinuationUseCaseProtocol {
    func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        .startFromBeginning
    }

    func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {}

    func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) {}

    func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity) {}
}

actor StubAudioMetadataCache: AudioMetadataCacheProtocol {
    func metadata(for track: PlaybackTrack, throttled: Bool) async -> AudioMetadata? { nil }

    func cachedMetadata(for track: PlaybackTrack) -> AudioMetadata? { nil }

    func removeAll() {}
}
