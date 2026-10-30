import Combine
import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGASwift

@MainActor
final class MockPlaybackEngine: PlaybackEngineProtocol {
    private let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let durationSubject = CurrentValueSubject<TimeInterval?, Never>(nil)
    private let playbackStatusSubject = CurrentValueSubject<PlaybackStatus, Never>(.idle)
    private let playbackSpeedSubject = CurrentValueSubject<Float, Never>(1)
    private let playbackRateSubject = CurrentValueSubject<Float, Never>(0)
    private let didPlayToEndSubject = PassthroughSubject<Void, Never>()

    private(set) var playedURLs: [URL] = []
    /// The URLs loaded without starting, in order — a subset of `playedURLs`.
    private(set) var loadedPausedURLs: [URL] = []
    private(set) var seekedSeconds: [TimeInterval] = []
    private(set) var togglePlayPauseCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var replayCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var unloadCallCount = 0

    /// `true` while an item is loaded — i.e. something can actually be heard.
    private(set) var isItemLoaded = false

    private(set) var isPlaybackIntended = false

    /// Duration reported for every item handed to `play(url:)`.
    var itemDuration: TimeInterval = 100

    /// When `true`, an item handed to `play(url:)` holds at `.buffering` until
    /// `simulateFirstFrame()` — the real engine's route into a track.
    var stallsBeforeFirstFrame = false

    /// When `true`, an item handed to `play(url:)` reports no duration until
    /// `simulateDurationReady()` — an item still reading its header.
    var withholdsDuration = false

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

    func play(url: URL, autoplay: Bool) {
        playedURLs.append(url)
        // As the real engine: a play asked for while nothing was loaded still stands
        isPlaybackIntended = autoplay || isPlaybackIntended
        if !isPlaybackIntended { loadedPausedURLs.append(url) }
        isItemLoaded = true
        currentTimeSubject.send(0)
        durationSubject.send(withholdsDuration ? nil : itemDuration)
        if isPlaybackIntended {
            playbackStatusSubject.send(stallsBeforeFirstFrame ? .buffering : .playing)
        } else {
            playbackStatusSubject.send(.paused)
        }
    }

    func unloadCurrentItem() {
        unloadCallCount += 1
        isItemLoaded = false
        isPlaybackIntended = false
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        playbackStatusSubject.send(.idle)
    }

    func togglePlayPause() {
        togglePlayPauseCallCount += 1
        isPlaybackIntended = playbackStatusSubject.value != .playing
        playbackStatusSubject.send(isPlaybackIntended ? .playing : .paused)
    }

    func pause() {
        pauseCallCount += 1
        isPlaybackIntended = false
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
        isPlaybackIntended = true
        currentTimeSubject.send(0)
    }

    func stop() {
        stopCallCount += 1
        isPlaybackIntended = false
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

    /// The item that was holding at `.buffering` produces its first audio.
    func simulateFirstFrame() {
        playbackStatusSubject.send(.playing)
    }

    /// The item that was withholding its duration reports it.
    func simulateDurationReady() {
        durationSubject.send(itemDuration)
    }

    /// The running item stalls part-way through.
    func simulateStall() {
        playbackStatusSubject.send(.buffering)
    }

    /// The system pauses the player (a phone call, say) — the listener still wants it playing.
    func simulateInterruption() {
        playbackStatusSubject.send(.paused)
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

    func savedPlaybackTime(for fingerprint: FingerprintEntity) -> TimeInterval? { nil }

    func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {}

    @discardableResult
    func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) -> PlaybackContinuationOutcomeEntity { .removed }

    func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity) {}
}

/// Metadata that never comes back — a remote parse that outlives the first frame.
actor NeverResolvingAudioMetadataCache: AudioMetadataCacheProtocol {
    func metadata(for track: PlaybackTrack, throttled: Bool) async -> AudioMetadata? {
        await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in }
        return nil
    }

    func cachedMetadata(for track: PlaybackTrack) -> AudioMetadata? { nil }

    func removeAll() {}
}

actor StubAudioMetadataCache: AudioMetadataCacheProtocol {
    func metadata(for track: PlaybackTrack, throttled: Bool) async -> AudioMetadata? { nil }

    func cachedMetadata(for track: PlaybackTrack) -> AudioMetadata? { nil }

    func removeAll() {}
}

/// Each offline track's metadata from a fixed table; `nil` for a track not in it.
actor FixedAudioMetadataCache: AudioMetadataCacheProtocol {
    private let metadataByURL: [URL: AudioMetadata]

    init(_ metadataByURL: [URL: AudioMetadata]) {
        self.metadataByURL = metadataByURL
    }

    func metadata(for track: PlaybackTrack, throttled: Bool) async -> AudioMetadata? {
        guard case .offline(let url) = track else { return nil }
        return metadataByURL[url]
    }

    func cachedMetadata(for track: PlaybackTrack) -> AudioMetadata? { nil }

    func removeAll() {}
}

/// Feeds node changes in on demand, standing in for the SDK's node updates.
struct MockAudioNodeUpdatesUseCase: AudioNodeUpdatesUseCaseProtocol {
    private let removedNodesStream: AnyAsyncSequence<[HandleEntity: NodeEntity?]>
    /// The service's way of telling the queued nodes and their folders, once it has subscribed
    private let queuedFoldersLookup = Atomic<(@Sendable () -> [HandleEntity: HandleEntity])?>(wrappedValue: nil)
    let removedFolderLinkNodes: AnyAsyncSequence<[HandleEntity: (any PlayableNode)?]>
    let renamedNodes: AnyAsyncSequence<[NodeEntity]>
    let renamedFolderLinkNodes: AnyAsyncSequence<[any PlayableNode]>
    private let continuation: AsyncStream<[HandleEntity: NodeEntity?]>.Continuation
    private let folderLinkContinuation: AsyncStream<[HandleEntity: (any PlayableNode)?]>.Continuation
    private let renameContinuation: AsyncStream<[NodeEntity]>.Continuation
    private let folderLinkRenameContinuation: AsyncStream<[any PlayableNode]>.Continuation

    init() {
        let (stream, continuation) = AsyncStream<[HandleEntity: NodeEntity?]>.makeStream()
        removedNodesStream = stream.eraseToAnyAsyncSequence()
        self.continuation = continuation

        let (folderLinkStream, folderLinkContinuation) = AsyncStream<[HandleEntity: (any PlayableNode)?]>.makeStream()
        removedFolderLinkNodes = folderLinkStream.eraseToAnyAsyncSequence()
        self.folderLinkContinuation = folderLinkContinuation

        let (renameStream, renameContinuation) = AsyncStream<[NodeEntity]>.makeStream()
        renamedNodes = renameStream.eraseToAnyAsyncSequence()
        self.renameContinuation = renameContinuation

        let (folderLinkRenameStream, folderLinkRenameContinuation) = AsyncStream<[any PlayableNode]>.makeStream()
        renamedFolderLinkNodes = folderLinkRenameStream.eraseToAnyAsyncSequence()
        self.folderLinkRenameContinuation = folderLinkRenameContinuation
    }

    func removedNodes(
        queuedFolders: @escaping @Sendable () -> [HandleEntity: HandleEntity]
    ) -> AnyAsyncSequence<[HandleEntity: NodeEntity?]> {
        queuedFoldersLookup.mutate { $0 = queuedFolders }
        return removedNodesStream
    }

    /// The queued nodes and their folders as the service tells them now; `nil` before it has subscribed
    var queuedFolders: [HandleEntity: HandleEntity]? {
        queuedFoldersLookup.wrappedValue?()
    }

    func simulateDeletion(ofNodeHandles handles: Set<HandleEntity>) {
        continuation.yield(Dictionary(uniqueKeysWithValues: handles.map { ($0, NodeEntity?.none) }))
    }

    /// - Parameter removals: the replacing node, keyed by the removed node's handle — `nil` for one
    ///   that is simply gone, so one update can carry replacements and deletions together
    func simulateRemoval(_ removals: [HandleEntity: NodeEntity?]) {
        continuation.yield(removals)
    }

    func simulateFolderLinkDeletion(ofNodeHandles handles: Set<HandleEntity>) {
        folderLinkContinuation.yield(Dictionary(uniqueKeysWithValues: handles.map { ($0, (any PlayableNode)?.none) }))
    }

    /// - Parameter removals: the replacing node, keyed by the removed node's handle — `nil` for one
    ///   that is simply gone, so one update can carry replacements and deletions together
    func simulateFolderLinkRemoval(_ removals: [HandleEntity: (any PlayableNode)?]) {
        folderLinkContinuation.yield(removals)
    }

    func simulateRename(of nodes: [NodeEntity]) {
        renameContinuation.yield(nodes)
    }

    func simulateFolderLinkRename(of nodes: [any PlayableNode]) {
        folderLinkRenameContinuation.yield(nodes)
    }
}

/// Records what reached the resume-position store, in order — the ordering is the
/// point, because `stop()` saves a position on its way out.
struct SpyPlaybackContinuationUseCase: PlaybackContinuationUseCaseProtocol {
    enum Operation: Equatable {
        case saved(FingerprintEntity)
        case removed(FingerprintEntity)
    }

    private let storage = Atomic<[Operation]>(wrappedValue: [])

    var operations: [Operation] { storage.wrappedValue }

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
        storage.mutate { $0.append(.saved(fingerprint)) }
        return .saved
    }

    func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity) {
        storage.mutate { $0.append(.removed(fingerprint)) }
    }
}
