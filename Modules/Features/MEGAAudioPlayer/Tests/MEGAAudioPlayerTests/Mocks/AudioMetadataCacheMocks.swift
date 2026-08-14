import Foundation
@testable import MEGAAudioPlayer

/// Counts how many times a metadata load is actually performed, so tests can
/// assert de-duplication. An `actor` keeps the counter race-free.
actor SpyMetadataLoader: AudioMetadataLoading {
    private(set) var loadCount = 0
    private let result: AudioMetadata
    private let delay: Duration

    init(result: AudioMetadata, delay: Duration = .zero) {
        self.result = result
        self.delay = delay
    }

    func loadMetadata(from url: URL) async throws -> AudioMetadata {
        loadCount += 1
        if delay > .zero { try? await Task.sleep(for: delay) }
        return result
    }
}

struct StubURLResolver: AudioTrackURLUseCaseProtocol {
    let resolvedURL: URL?
    func url(for track: PlaybackTrack) -> URL? { resolvedURL }
}

/// Resolves an offline track to its own file URL, so distinct tracks map to
/// distinct URLs (lets a loader tell them apart).
struct OfflinePassthroughURLResolver: AudioTrackURLUseCaseProtocol {
    func url(for track: PlaybackTrack) -> URL? {
        if case let .offline(url) = track { return url }
        return nil
    }
}

/// Admits every track its URL provider can address, and never reports a takedown.
/// Answers from the cache path, so playback starts synchronously the way it does
/// for offline files in production.
@MainActor
final class PassthroughTrackResolver: AudioTrackResolutionUseCaseProtocol {
    private let urlUseCase: any AudioTrackURLUseCaseProtocol
    private(set) var resetCallCount = 0

    init(urlUseCase: some AudioTrackURLUseCaseProtocol = OfflinePassthroughURLResolver()) {
        self.urlUseCase = urlUseCase
    }

    func cachedResolution(for track: PlaybackTrack) -> AudioURLResolution? {
        guard let url = urlUseCase.url(for: track) else { return .unresolved }
        return .resolved(url)
    }

    func resolve(_ track: PlaybackTrack) async -> AudioURLResolution {
        cachedResolution(for: track) ?? .unresolved
    }

    func reset() { resetCallCount += 1 }
}

/// Reports the given tracks as taken down, and only after a suspension — so tests
/// exercise the same asynchronous path a real probe takes.
@MainActor
final class StubTakenDownTrackResolver: AudioTrackResolutionUseCaseProtocol {
    private let takenDownURLs: Set<URL>
    private(set) var resolveCallCount = 0

    /// Caches verdicts the way the real use case does, so revisiting a track takes
    /// the synchronous path instead of probing again.
    private var verdicts: [String: AudioURLResolution] = [:]

    init(takenDown: [URL]) {
        self.takenDownURLs = Set(takenDown)
    }

    func cachedResolution(for track: PlaybackTrack) -> AudioURLResolution? {
        verdicts[track.id]
    }

    func resolve(_ track: PlaybackTrack) async -> AudioURLResolution {
        resolveCallCount += 1
        await Task.yield()
        let resolution = verdict(for: track)
        verdicts[track.id] = resolution
        return resolution
    }

    func reset() { verdicts.removeAll() }

    private func verdict(for track: PlaybackTrack) -> AudioURLResolution {
        guard case let .offline(url) = track else { return .unresolved }
        return takenDownURLs.contains(url) ? .takenDown : .resolved(url)
    }
}

/// Blocks every load until `openGate()` — except `immediateURL`, which returns
/// at once. Lets a test hold the concurrency slots occupied while checking that
/// an un-throttled load still gets through. `blockedCount` reports how many
/// loads are currently parked.
actor GatedMetadataLoader: AudioMetadataLoading {
    private let immediateURL: URL
    private let result: AudioMetadata
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private(set) var blockedCount = 0

    init(immediateURL: URL, result: AudioMetadata) {
        self.immediateURL = immediateURL
        self.result = result
    }

    func loadMetadata(from url: URL) async throws -> AudioMetadata {
        if url == immediateURL { return result }
        blockedCount += 1
        await withCheckedContinuation { waiters.append($0) }
        return result
    }

    func openGate() {
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}
