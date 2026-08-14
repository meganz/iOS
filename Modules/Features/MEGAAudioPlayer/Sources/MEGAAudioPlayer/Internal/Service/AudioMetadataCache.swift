import Foundation

// MARK: - Protocol

/// In-memory cache for per-track ``AudioMetadata`` (title / artist / album / artwork)
protocol AudioMetadataCacheProtocol: Actor {
    /// Returns cached metadata if present; otherwise resolves the track's URL,
    /// loads its metadata, caches it, and returns it. `throttled` loads wait for
    /// a concurrency slot; the actively-playing item passes `throttled: false`
    /// so it is never starved behind queue-row prefetches.
    func metadata(for track: PlaybackTrack, throttled: Bool) async -> AudioMetadata?

    /// Returns already-cached metadata without triggering a load — `nil` if it
    /// hasn't been loaded yet
    func cachedMetadata(for track: PlaybackTrack) -> AudioMetadata?

    /// Drops all cached entries
    func removeAll()
}

extension AudioMetadataCacheProtocol {
    /// Convenience: a throttled load, used by queue-row prefetches.
    func metadata(for track: PlaybackTrack) async -> AudioMetadata? {
        await metadata(for: track, throttled: true)
    }
}

// MARK: - Implementation

actor AudioMetadataCache: AudioMetadataCacheProtocol {
    private let urlUseCase: any AudioTrackURLUseCaseProtocol
    private let metadataLoader: any AudioMetadataLoading

    private var store: [String: AudioMetadata] = [:]
    private var inFlight: [String: Task<AudioMetadata?, Never>] = [:]

    private let maxConcurrentLoads = 3
    private var activeLoads = 0
    private var loadWaiters: [CheckedContinuation<Void, Never>] = []

    private var memoryWarningTask: Task<Void, Never>?

    init(
        urlUseCase: some AudioTrackURLUseCaseProtocol = AudioTrackURLUseCase(),
        metadataLoader: some AudioMetadataLoading = AudioMetadataLoader(),
        notificationCenter: NotificationCenter = .default,
        memoryWarningNotification: Notification.Name = DependencyInjection.memoryWarningNotification
    ) {
        self.urlUseCase = urlUseCase
        self.metadataLoader = metadataLoader
        Task { await self.startObservingMemoryWarnings(on: notificationCenter, named: memoryWarningNotification) }
    }

    deinit {
        memoryWarningTask?.cancel()
    }

    private func startObservingMemoryWarnings(on notificationCenter: NotificationCenter, named name: Notification.Name) {
        memoryWarningTask = Task { [weak self] in
            for await _ in notificationCenter.notifications(named: name) {
                await self?.removeAll()
            }
        }
    }

    func metadata(for track: PlaybackTrack, throttled: Bool) async -> AudioMetadata? {
        let key = track.id

        if let cached = store[key] { return cached }
        if let task = inFlight[key] { return await task.value }

        let url = urlUseCase.url(for: track)
        let loader = metadataLoader
        let task = Task<AudioMetadata?, Never> {
            guard let url else { return nil }
            if throttled { await acquireLoadSlot() }
            defer { if throttled { releaseLoadSlot() } }
            return try? await loader.loadMetadata(from: url)
        }
        inFlight[key] = task

        let metadata = await task.value
        inFlight[key] = nil
        if let metadata { store[key] = metadata }
        return metadata
    }

    /// Suspends until a load slot is free (at most `maxConcurrentLoads` at once).
    private func acquireLoadSlot() async {
        if activeLoads < maxConcurrentLoads {
            activeLoads += 1
            return
        }
        await withCheckedContinuation { loadWaiters.append($0) }
    }

    /// Releases a slot, passing it straight to the next waiter if there is one.
    private func releaseLoadSlot() {
        if loadWaiters.isEmpty {
            activeLoads -= 1
        } else {
            loadWaiters.removeFirst().resume()
        }
    }

    func cachedMetadata(for track: PlaybackTrack) -> AudioMetadata? {
        store[track.id]
    }

    func removeAll() {
        store.removeAll()
        inFlight.removeAll()
    }
}
