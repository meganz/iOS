import Foundation
import MEGADomain
import MEGASwift
import ViewedLinks

/// Mock `ViewedLinksUseCaseProtocol` for tests.
public final class MockViewedLinksUseCase: ViewedLinksUseCaseProtocol, @unchecked Sendable {
    public var viewedLinksResult: [ViewedLinkEntity]
    public var topViewedLinksResult: [ViewedLinkEntity]
    public var errorToThrow: ViewedLinkErrorEntity?
    public var changesSignalSequenceResult: AnyAsyncSequence<Void> = AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()

    public private(set) var recordedLinks: [ViewedLinkEntity] = []
    public private(set) var removedLinks: [[ViewedLinkEntity]] = []
    public private(set) var removedUnavailableURLs: [URL] = []
    public private(set) var clearHistoryCallCount = 0
    public private(set) var lastTopLimit: Int?

    public var recordCallCount: Int { recordedLinks.count }

    public init(
        viewedLinksResult: [ViewedLinkEntity] = [],
        topViewedLinksResult: [ViewedLinkEntity] = [],
        errorToThrow: ViewedLinkErrorEntity? = nil
    ) {
        self.viewedLinksResult = viewedLinksResult
        self.topViewedLinksResult = topViewedLinksResult
        self.errorToThrow = errorToThrow
    }

    public func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        try throwIfNeeded()
        return viewedLinksResult
    }

    public func topViewedLinks(limit: Int) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        lastTopLimit = limit
        try throwIfNeeded()
        return Array(topViewedLinksResult.prefix(limit))
    }

    public func record(_ link: ViewedLinkEntity) async throws(ViewedLinkErrorEntity) {
        recordedLinks.append(link)
        try throwIfNeeded()
    }

    public func remove(_ links: [ViewedLinkEntity]) async throws(ViewedLinkErrorEntity) {
        removedLinks.append(links)
        try throwIfNeeded()
    }

    public func removeUnavailable(linkURL: URL) async throws(ViewedLinkErrorEntity) {
        removedUnavailableURLs.append(linkURL)
        try throwIfNeeded()
    }

    public func clearHistory() async throws(ViewedLinkErrorEntity) {
        clearHistoryCallCount += 1
        try throwIfNeeded()
    }

    public func changesSignalSequence() -> AnyAsyncSequence<Void> {
        changesSignalSequenceResult
    }

    private func throwIfNeeded() throws(ViewedLinkErrorEntity) {
        if let errorToThrow { throw errorToThrow }
    }
}
