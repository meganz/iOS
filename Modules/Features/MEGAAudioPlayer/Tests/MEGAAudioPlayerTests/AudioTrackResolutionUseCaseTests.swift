import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
struct AudioTrackResolutionUseCaseTests {

    @Test("A track keeps its verdict, so the same track is probed only once")
    func verdictIsReused() async {
        let repo = MockNodeAvailabilityRepository(isTakenDown: false)
        let sut = makeSUT(repo: repo)

        _ = await sut.resolve(accountTrack)
        _ = await sut.resolve(accountTrack)

        #expect(repo.probeCount == 1)
        #expect(sut.cachedResolution(for: accountTrack) == .resolved(streamingURL))
    }

    @Test("A taken-down verdict is reported and reused")
    func takenDownVerdictIsReused() async {
        let repo = MockNodeAvailabilityRepository(isTakenDown: true)
        let sut = makeSUT(repo: repo)

        let first = await sut.resolve(accountTrack)
        let second = await sut.resolve(accountTrack)

        #expect(first == .takenDown)
        #expect(second == .takenDown)
        #expect(repo.probeCount == 1)
    }

    @Test("A probe that could not complete lets the track play but is not remembered")
    func inconclusiveProbeIsNotCached() async {
        let repo = MockNodeAvailabilityRepository(error: NSError(domain: "offline", code: -1))
        let sut = makeSUT(repo: repo)

        let resolution = await sut.resolve(accountTrack)

        #expect(resolution == .resolved(streamingURL), "a network blip must not read as a takedown")
        #expect(sut.cachedResolution(for: accountTrack) == nil, "a guess must not become a verdict")

        // ...and the next attempt asks again rather than trusting the guess.
        _ = await sut.resolve(accountTrack)
        #expect(repo.probeCount == 2)
    }

    @Test("Resetting drops the session's verdicts")
    func resetDropsVerdicts() async {
        let repo = MockNodeAvailabilityRepository(isTakenDown: false)
        let sut = makeSUT(repo: repo)

        _ = await sut.resolve(accountTrack)
        sut.reset()

        #expect(sut.cachedResolution(for: accountTrack) == nil)
        _ = await sut.resolve(accountTrack)
        #expect(repo.probeCount == 2)
    }

    @Test("An offline file is admitted without ever asking the API")
    func offlineTrackIsNeverProbed() async {
        let repo = MockNodeAvailabilityRepository(isTakenDown: true)
        let sut = AudioTrackResolutionUseCase(
            urlUseCase: OfflinePassthroughURLResolver(),
            availabilityRepository: repo
        )
        let offline = PlaybackTrack.offline(localFile)

        #expect(sut.cachedResolution(for: offline) == .resolved(localFile))
        #expect(await sut.resolve(offline) == .resolved(localFile))
        #expect(repo.probeCount == 0)
    }

    @Test("A node playing from its downloaded copy is admitted without a probe")
    func downloadedTrackIsNeverProbed() async {
        // Offline the probe would not fail — the SDK keeps retrying it — so a downloaded
        // track that waited for a verdict would never start (IOS-12508).
        let repo = MockNodeAvailabilityRepository(isTakenDown: true)
        let sut = AudioTrackResolutionUseCase(
            urlUseCase: StubURLResolver(resolvedURL: localFile),
            availabilityRepository: repo
        )

        #expect(sut.cachedResolution(for: accountTrack) == .resolved(localFile))
        #expect(await sut.resolve(accountTrack) == .resolved(localFile))
        #expect(repo.probeCount == 0)
    }

    @Test("A track with no address is unplayable without a probe")
    func unaddressableTrackIsUnresolved() async {
        let repo = MockNodeAvailabilityRepository(isTakenDown: false)
        let sut = AudioTrackResolutionUseCase(
            urlUseCase: StubURLResolver(resolvedURL: nil),
            availabilityRepository: repo
        )

        #expect(await sut.resolve(accountTrack) == .unresolved)
        #expect(repo.probeCount == 0)
    }

    // MARK: - Helpers

    /// Deliberately not a file URL: a file URL means "already on the device", which is
    /// admitted without a probe.
    private var streamingURL: URL { URL(string: "http://127.0.0.1:4443/track.mp3")! }

    private var localFile: URL { URL(fileURLWithPath: "/Offline/track.mp3") }

    private var accountTrack: PlaybackTrack {
        .account(NodeEntity(handle: 1))
    }

    private func makeSUT(repo: MockNodeAvailabilityRepository) -> AudioTrackResolutionUseCase {
        AudioTrackResolutionUseCase(
            urlUseCase: StubURLResolver(resolvedURL: streamingURL),
            availabilityRepository: repo
        )
    }
}

/// Counts probes so tests can tell a cached verdict from a fresh round-trip.
private final class MockNodeAvailabilityRepository: AudioNodeAvailabilityRepositoryProtocol, @unchecked Sendable {
    static var newRepo: MockNodeAvailabilityRepository { MockNodeAvailabilityRepository(isTakenDown: false) }

    private(set) var probeCount = 0
    private let isTakenDown: Bool
    private let error: (any Error)?

    init(isTakenDown: Bool = false, error: (any Error)? = nil) {
        self.isTakenDown = isTakenDown
        self.error = error
    }

    func isTakenDown(_ node: StreamingNode) async throws -> Bool {
        probeCount += 1
        if let error { throw error }
        return isTakenDown
    }
}
