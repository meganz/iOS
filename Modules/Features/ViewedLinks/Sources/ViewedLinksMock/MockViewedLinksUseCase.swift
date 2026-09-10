import Foundation
import MEGASwift
import ViewedLinks

/// Mock `ViewedLinksUseCaseProtocol` for tests.
public final class MockViewedLinksUseCase: ViewedLinksUseCaseProtocol, @unchecked Sendable {
    public var viewedLinksResult: [ViewedLinkEntity]
    public var topViewedLinksResult: [ViewedLinkEntity]
    public var changesSignalSequenceResult: AnyAsyncSequence<Void> = AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()

    public private(set) var recordedLinks: [ViewedLinkEntity] = []
    public private(set) var removedLinks: [[ViewedLinkEntity]] = []
    public private(set) var removedUnavailableURLs: [URL] = []
    public private(set) var clearHistoryCallCount = 0

    public var recordCallCount: Int { recordedLinks.count }

    public init(
        viewedLinksResult: [ViewedLinkEntity] = [],
        topViewedLinksResult: [ViewedLinkEntity] = []
    ) {
        self.viewedLinksResult = viewedLinksResult
        self.topViewedLinksResult = topViewedLinksResult
    }

    public func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        viewedLinksResult
    }

    public func topViewedLinks(limit: Int) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        Array(topViewedLinksResult.prefix(limit))
    }

    public func record(_ link: ViewedLinkEntity) async throws(ViewedLinkErrorEntity) {
        recordedLinks.append(link)
    }

    public func remove(_ links: [ViewedLinkEntity]) async throws(ViewedLinkErrorEntity) {
        removedLinks.append(links)
    }

    public func removeUnavailable(linkURL: URL) async throws(ViewedLinkErrorEntity) {
        removedUnavailableURLs.append(linkURL)
    }

    public func clearHistory() async throws(ViewedLinkErrorEntity) {
        clearHistoryCallCount += 1
    }

    public func changesSignalSequence() -> AnyAsyncSequence<Void> {
        changesSignalSequenceResult
    }
}
