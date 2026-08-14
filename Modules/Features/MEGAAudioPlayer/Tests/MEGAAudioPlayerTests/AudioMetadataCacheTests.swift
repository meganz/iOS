import Foundation
@testable import MEGAAudioPlayer
import Testing

@Suite("AudioMetadataCache")
struct AudioMetadataCacheTests {
    static let sampleMetadata = AudioMetadata(title: "Title", artist: "Artist", album: "Album", artworkData: nil)

    static func makeSUT(
        resolvedURL: URL? = URL(fileURLWithPath: "/audio/song.mp3"),
        result: AudioMetadata = sampleMetadata,
        loadDelay: Duration = .zero,
        notificationCenter: NotificationCenter = .default,
        memoryWarningNotification: Notification.Name = .init("test.memoryWarning")
    ) -> (sut: AudioMetadataCache, loader: SpyMetadataLoader) {
        let loader = SpyMetadataLoader(result: result, delay: loadDelay)
        let sut = AudioMetadataCache(
            urlUseCase: StubURLResolver(resolvedURL: resolvedURL),
            metadataLoader: loader,
            notificationCenter: notificationCenter,
            memoryWarningNotification: memoryWarningNotification
        )
        return (sut, loader)
    }

    static func makeTrack(_ path: String = "/audio/song.mp3") -> PlaybackTrack {
        .offline(URL(fileURLWithPath: path))
    }

    @Test("Resolves + loads on first read, serves from cache on the second")
    func loadsAndCaches() async {
        let (sut, loader) = Self.makeSUT()
        let track = Self.makeTrack()

        #expect(await sut.metadata(for: track) == Self.sampleMetadata)
        #expect(await sut.metadata(for: track) == Self.sampleMetadata)
        #expect(await loader.loadCount == 1)
    }

    @Test("cachedMetadata is nil before a load and returns the value after")
    func cachedMetadataReflectsLoad() async {
        let (sut, _) = Self.makeSUT()
        let track = Self.makeTrack()

        #expect(await sut.cachedMetadata(for: track) == nil)
        _ = await sut.metadata(for: track)
        #expect(await sut.cachedMetadata(for: track) == Self.sampleMetadata)
    }

    @Test("Concurrent requests for the same track share a single load")
    func concurrentRequestsShareOneLoad() async {
        let (sut, loader) = Self.makeSUT(loadDelay: .milliseconds(50))
        let track = Self.makeTrack()

        async let a = sut.metadata(for: track)
        async let b = sut.metadata(for: track)
        async let c = sut.metadata(for: track)
        let results = await [a, b, c]

        #expect(results.allSatisfy { $0 == Self.sampleMetadata })
        #expect(await loader.loadCount == 1)
    }

    @Test("Unresolvable URL returns nil without loading")
    func unresolvableURLReturnsNil() async {
        let (sut, loader) = Self.makeSUT(resolvedURL: nil)

        #expect(await sut.metadata(for: Self.makeTrack()) == nil)
        #expect(await loader.loadCount == 0)
    }

    @Test("removeAll clears entries; a later read loads again")
    func removeAllClears() async {
        let (sut, loader) = Self.makeSUT()
        let track = Self.makeTrack()

        _ = await sut.metadata(for: track)
        #expect(await sut.cachedMetadata(for: track) == Self.sampleMetadata)

        await sut.removeAll()
        #expect(await sut.cachedMetadata(for: track) == nil)

        _ = await sut.metadata(for: track)
        #expect(await loader.loadCount == 2)
    }

    @Test("An un-throttled (playing-item) load runs even while the throttle is saturated")
    func unthrottledLoadBypassesSaturatedThrottle() async {
        let currentURL = URL(fileURLWithPath: "/audio/current.mp3")
        let loader = GatedMetadataLoader(immediateURL: currentURL, result: Self.sampleMetadata)
        let sut = AudioMetadataCache(
            urlUseCase: OfflinePassthroughURLResolver(),
            metadataLoader: loader,
            notificationCenter: NotificationCenter(),
            memoryWarningNotification: .init("test.memoryWarning")
        )

        // Saturate every load slot (mirrors `maxConcurrentLoads`) with throttled
        // loads that block inside the loader and therefore hold their slots.
        for i in 0..<3 {
            let blocker = PlaybackTrack.offline(URL(fileURLWithPath: "/audio/block-\(i).mp3"))
            Task { _ = await sut.metadata(for: blocker, throttled: true) }
        }
        for _ in 0..<200 {
            if await loader.blockedCount >= 3 { break }
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(await loader.blockedCount == 3)

        // The un-throttled load must complete despite every slot being held.
        // Race a timeout so a regression fails fast instead of hanging.
        let current = PlaybackTrack.offline(currentURL)
        let result = await withTaskGroup(of: AudioMetadata?.self) { group in
            group.addTask { await sut.metadata(for: current, throttled: false) }
            group.addTask {
                try? await Task.sleep(for: .seconds(1))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        #expect(result == Self.sampleMetadata)

        await loader.openGate() // release the blocked loads so nothing lingers
    }

    @Test("A memory-warning notification clears the cache")
    func memoryWarningClears() async {
        let center = NotificationCenter()
        let warning = Notification.Name("test.memoryWarning")
        let (sut, _) = Self.makeSUT(notificationCenter: center, memoryWarningNotification: warning)
        let track = Self.makeTrack()

        _ = await sut.metadata(for: track)
        #expect(await sut.cachedMetadata(for: track) == Self.sampleMetadata)

        // The observer registers asynchronously once the actor's Task starts
        // iterating; re-post while polling so we don't race its setup.
        var cleared = false
        for _ in 0..<100 {
            center.post(name: warning, object: nil)
            try? await Task.sleep(for: .milliseconds(5))
            if await sut.cachedMetadata(for: track) == nil { cleared = true; break }
        }
        #expect(cleared)
    }
}
