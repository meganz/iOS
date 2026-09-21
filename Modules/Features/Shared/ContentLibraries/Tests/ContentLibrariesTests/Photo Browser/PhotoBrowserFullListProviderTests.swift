@testable import ContentLibraries
import MEGADomain
import Testing

@Suite("PhotoBrowserFullListProvider")
struct PhotoBrowserFullListProviderTests {

    @Test("Asks for the whole list in one unbounded query from the top")
    func unboundedFromTheTop() async throws {
        let script = MediaTimelinePageScript(forward: [.success([.photoA, .photoB])])

        let nodes = try await makeSUT(script: script).fullList(of: .videos)

        #expect(nodes.map(\.handle) == [1, 2])
        // Zero is the SDK's "no limit". A bound guessed from the loaded count would drop the
        // oldest items of a descending query as new ones arrive.
        #expect(await script.limits == [0])
        #expect(await script.forwardAnchors == [nil])
    }

    @Test("Narrows the media type and keeps the rest of the browser's query")
    func narrowsMediaTypeOnly() async throws {
        let script = MediaTimelinePageScript(forward: [.success([.photoA])])
        let sut = makeSUT(
            script: script,
            filter: MediaTimelineFilterEntity(mediaType: .allMedia, location: .cameraUploads),
            sortOrder: .oldest)

        _ = try await sut.fullList(of: .images)

        let query = try #require(await script.forwardQueries.first)
        #expect(query.filter == MediaTimelineFilterEntity(mediaType: .images, location: .cameraUploads))
        #expect(query.sortOrder == .oldest)
    }

    @Test("Passes an empty list straight through rather than reading anything into it")
    func emptyIsNotSpecial() async throws {
        let nodes = try await makeSUT(script: MediaTimelinePageScript(forward: [.success([])]))
            .fullList(of: .images)

        #expect(nodes.isEmpty)
    }

    @Test("Propagates a failed query")
    func failurePropagates() async {
        let sut = makeSUT(script: MediaTimelinePageScript(forward: [.failure(PaginationTestError.pageFailed)]))

        await #expect(throws: PaginationTestError.self) {
            _ = try await sut.fullList(of: .images)
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        script: MediaTimelinePageScript,
        filter: MediaTimelineFilterEntity = MediaTimelineFilterEntity(mediaType: .allMedia, location: .allLocations),
        sortOrder: MediaTimelineSortOrderEntity = .newest
    ) -> PhotoBrowserFullListProvider {
        PhotoBrowserFullListProvider(
            context: makePaginationContext(nodes: [], sortOrder: sortOrder, filter: filter),
            useCase: StubMediaTimelineUseCase(script: script))
    }
}
