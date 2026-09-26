import Foundation
import MEGADomain
import MEGASwift
import Testing
@testable import ViewedLinks

@Suite("ViewedLinksRepository")
struct ViewedLinksRepositoryTests {
    /// Minimal in-test store: throws `error` from every operation when set,
    /// otherwise returns canned results. Lets us exercise the repository's
    /// error-mapping boundary without a real store.
    private final class StubViewedLinksStore: ViewedLinksStoreProtocol, @unchecked Sendable {
        var error: (any Error)?
        var viewedLinksResult: [ViewedLinkEntity] = []
        var signal: AnyAsyncSequence<Void> = AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()

        private func check() throws {
            if let error { throw error }
        }

        func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws -> [ViewedLinkEntity] {
            try check()
            return viewedLinksResult
        }
        func topViewedLinks(limit: Int) async throws -> [ViewedLinkEntity] {
            try check()
            return viewedLinksResult
        }
        func record(_ link: ViewedLinkEntity) async throws { try check() }
        func remove(_ links: [ViewedLinkEntity]) async throws { try check() }
        func removeUnavailable(linkURL: URL) async throws { try check() }
        func clearHistory() async throws { try check() }
        func changesSignalSequence() -> AnyAsyncSequence<Void> { signal }
    }

    private func makeLink(handle: HandleEntity = 1) throws -> ViewedLinkEntity {
        let url = try #require(URL(string: "https://mega.nz/file/\(handle)#key"))
        return ViewedLinkEntity(handle: handle, linkURL: url, name: "f\(handle)", isFolder: false, hasThumbnail: false, lastAccessed: Date(timeIntervalSince1970: 0))
    }

    @Test("maps a raw store error to .storeOperationFailed across all operations")
    func mapsStoreErrorToPersistenceFailed() async throws {
        let store = StubViewedLinksStore()
        store.error = NSError(domain: NSCocoaErrorDomain, code: 256)
        let sut = ViewedLinksRepository(store: store)
        let link = try makeLink()

        await #expect(throws: ViewedLinkErrorEntity.storeOperationFailed) { _ = try await sut.viewedLinks(sortedBy: .name, ascending: true) }
        await #expect(throws: ViewedLinkErrorEntity.storeOperationFailed) { _ = try await sut.topViewedLinks(limit: 4) }
        await #expect(throws: ViewedLinkErrorEntity.storeOperationFailed) { try await sut.record(link) }
        await #expect(throws: ViewedLinkErrorEntity.storeOperationFailed) { try await sut.remove([link]) }
        await #expect(throws: ViewedLinkErrorEntity.storeOperationFailed) { try await sut.removeUnavailable(linkURL: link.linkURL) }
        await #expect(throws: ViewedLinkErrorEntity.storeOperationFailed) { try await sut.clearHistory() }
    }

    @Test("maps CancellationError to .cancelled")
    func mapsCancellationToCancelled() async throws {
        let store = StubViewedLinksStore()
        store.error = CancellationError()
        let sut = ViewedLinksRepository(store: store)

        await #expect(throws: ViewedLinkErrorEntity.cancelled) { _ = try await sut.viewedLinks(sortedBy: .name, ascending: true) }
    }

    @Test("passes results through on success")
    func passesResultsThrough() async throws {
        let store = StubViewedLinksStore()
        store.viewedLinksResult = try [makeLink(handle: 1), makeLink(handle: 2)]
        let sut = ViewedLinksRepository(store: store)

        let result = try await sut.viewedLinks(sortedBy: .name, ascending: true)
        #expect(result.map(\.handle) == [1, 2])
    }

    @Test("forwards the change signal from the store")
    func forwardsChangeSignal() async throws {
        let store = StubViewedLinksStore()
        store.signal = AsyncStream<Void> { continuation in
            continuation.yield(())
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let sut = ViewedLinksRepository(store: store)

        var count = 0
        for await _ in sut.changesSignalSequence() { count += 1 }
        #expect(count == 1)
    }
}
