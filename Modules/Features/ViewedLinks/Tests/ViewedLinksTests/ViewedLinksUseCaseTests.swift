import Foundation
import MEGADomain
import MEGASwift
import Testing
import ViewedLinks
@testable import ViewedLinksMock

@Suite("ViewedLinksUseCase")
struct ViewedLinksUseCaseTests {
    private func makeLink(handle: HandleEntity = 1) throws -> ViewedLinkEntity {
        let url = try #require(URL(string: "https://mega.nz/file/\(handle)#key"))
        return ViewedLinkEntity(handle: handle, linkURL: url, name: "f\(handle)", isFolder: false, hasThumbnail: false, lastAccessed: Date(timeIntervalSince1970: 0))
    }

    @Test("record forwards to the repository")
    func recordForwards() async throws {
        let repo = MockViewedLinksRepository()
        let sut = ViewedLinksUseCase(repository: repo)
        let link = try makeLink(handle: 3)

        try await sut.record(link)
        #expect(repo.recordedLinks.map(\.handle) == [3])
    }

    @Test("viewedLinks forwards sort key + direction and returns the result")
    func viewedLinksForwardsSort() async throws {
        let expected = try [makeLink(handle: 1), makeLink(handle: 2)]
        let repo = MockViewedLinksRepository(viewedLinksResult: expected)
        let sut = ViewedLinksUseCase(repository: repo)

        let result = try await sut.viewedLinks(sortedBy: .name, ascending: false)
        #expect(result.map(\.handle) == [1, 2])
        #expect(repo.lastSortKey == .name)
        #expect(repo.lastAscending == false)
    }

    @Test("topViewedLinks forwards the limit")
    func topViewedLinksForwardsLimit() async throws {
        let repo = MockViewedLinksRepository(topViewedLinksResult: try (1...10).map { try makeLink(handle: HandleEntity($0)) })
        let sut = ViewedLinksUseCase(repository: repo)

        let result = try await sut.topViewedLinks(limit: 4)
        #expect(repo.lastTopLimit == 4)
        #expect(result.count == 4)
    }

    @Test("remove forwards to the repository")
    func removeForwards() async throws {
        let repo = MockViewedLinksRepository()
        let sut = ViewedLinksUseCase(repository: repo)
        let links = try [makeLink(handle: 1), makeLink(handle: 2)]

        try await sut.remove(links)
        #expect(repo.removedLinks.count == 1)
        #expect(repo.removedLinks.first?.map(\.handle) == [1, 2])
    }

    @Test("removeUnavailable forwards the URL")
    func removeUnavailableForwards() async throws {
        let repo = MockViewedLinksRepository()
        let sut = ViewedLinksUseCase(repository: repo)
        let url = try #require(URL(string: "https://mega.nz/file/dead#k"))

        try await sut.removeUnavailable(linkURL: url)
        #expect(repo.removedUnavailableURLs == [url])
    }

    @Test("clearHistory forwards to the repository")
    func clearHistoryForwards() async throws {
        let repo = MockViewedLinksRepository()
        let sut = ViewedLinksUseCase(repository: repo)

        try await sut.clearHistory()
        #expect(repo.clearHistoryCallCount == 1)
    }

    @Test("changesSignalSequence forwards the repository signal")
    func changesSignalForwards() async throws {
        let repo = MockViewedLinksRepository()
        repo.changesSignalSequenceResult = AsyncStream<Void> { continuation in
            continuation.yield(())
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let sut = ViewedLinksUseCase(repository: repo)

        var count = 0
        for await _ in sut.changesSignalSequence() { count += 1 }
        #expect(count == 1)
    }
}
