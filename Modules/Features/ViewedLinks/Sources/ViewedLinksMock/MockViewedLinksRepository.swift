import Foundation
import MEGASwift
import ViewedLinks

/// Mock `ViewedLinksRepositoryProtocol` for tests.
package final class MockViewedLinksRepository: ViewedLinksRepositoryProtocol, @unchecked Sendable {
    package var viewedLinksResult: [ViewedLinkEntity]
    package var topViewedLinksResult: [ViewedLinkEntity]
    package var errorToThrow: ViewedLinkErrorEntity?
    package var changesSignalSequenceResult: AnyAsyncSequence<Void> = AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()

    package private(set) var recordedLinks: [ViewedLinkEntity] = []
    package private(set) var removedLinks: [[ViewedLinkEntity]] = []
    package private(set) var removedUnavailableURLs: [URL] = []
    package private(set) var clearHistoryCallCount = 0
    package private(set) var lastSortKey: ViewedLinksSortKey?
    package private(set) var lastAscending: Bool?
    package private(set) var lastTopLimit: Int?

    package init(
        viewedLinksResult: [ViewedLinkEntity] = [],
        topViewedLinksResult: [ViewedLinkEntity] = [],
        errorToThrow: ViewedLinkErrorEntity? = nil
    ) {
        self.viewedLinksResult = viewedLinksResult
        self.topViewedLinksResult = topViewedLinksResult
        self.errorToThrow = errorToThrow
    }

    package func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        lastSortKey = sortKey
        lastAscending = ascending
        try throwIfNeeded()
        return viewedLinksResult
    }

    package func topViewedLinks(limit: Int) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        lastTopLimit = limit
        try throwIfNeeded()
        return Array(topViewedLinksResult.prefix(limit))
    }

    package func record(_ link: ViewedLinkEntity) async throws(ViewedLinkErrorEntity) {
        recordedLinks.append(link)
        try throwIfNeeded()
    }

    package func remove(_ links: [ViewedLinkEntity]) async throws(ViewedLinkErrorEntity) {
        removedLinks.append(links)
        try throwIfNeeded()
    }

    package func removeUnavailable(linkURL: URL) async throws(ViewedLinkErrorEntity) {
        removedUnavailableURLs.append(linkURL)
        try throwIfNeeded()
    }

    package func clearHistory() async throws(ViewedLinkErrorEntity) {
        clearHistoryCallCount += 1
        try throwIfNeeded()
    }

    package func changesSignalSequence() -> AnyAsyncSequence<Void> {
        changesSignalSequenceResult
    }

    private func throwIfNeeded() throws(ViewedLinkErrorEntity) {
        if let errorToThrow { throw errorToThrow }
    }
}
