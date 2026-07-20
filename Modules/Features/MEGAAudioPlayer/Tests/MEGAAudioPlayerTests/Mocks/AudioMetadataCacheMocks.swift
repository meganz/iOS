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

struct StubURLResolver: AudioURLResolutionUseCaseProtocol {
    let resolvedURL: URL?
    func url(for track: PlaybackTrack) -> URL? { resolvedURL }
}

/// Resolves an offline track to its own file URL, so distinct tracks map to
/// distinct URLs (lets a loader tell them apart).
struct OfflinePassthroughURLResolver: AudioURLResolutionUseCaseProtocol {
    func url(for track: PlaybackTrack) -> URL? {
        if case let .offline(url) = track { return url }
        return nil
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
