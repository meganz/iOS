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
        #expect(sut.cachedResolution(for: accountTrack) == .resolved(url))
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

        #expect(resolution == .resolved(url), "a network blip must not read as a takedown")
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
        let sut = makeSUT(repo: repo)
        let offline = PlaybackTrack.offline(url)

        #expect(sut.cachedResolution(for: offline) == .resolved(url))
        #expect(await sut.resolve(offline) == .resolved(url))
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

    private var url: URL { URL(fileURLWithPath: "/tmp/track.mp3") }

    private var accountTrack: PlaybackTrack {
        .account(NodeEntity(handle: 1))
    }

    private func makeSUT(repo: MockNodeAvailabilityRepository) -> AudioTrackResolutionUseCase {
        AudioTrackResolutionUseCase(
            urlUseCase: StubURLResolver(resolvedURL: url),
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
