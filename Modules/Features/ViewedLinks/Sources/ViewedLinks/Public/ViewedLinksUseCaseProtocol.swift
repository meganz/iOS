import Foundation
import MEGASwift

/// Business actions over the user's viewed-links history.
public protocol ViewedLinksUseCaseProtocol: Sendable {
    /// All viewed links, sorted by the given key and direction.
    func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity]
    /// The most recently accessed links, capped at `limit`.
    func topViewedLinks(limit: Int) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity]
    /// Upsert a link, keyed by handle.
    func record(_ link: ViewedLinkEntity) async throws(ViewedLinkErrorEntity)
    /// Remove the given links.
    func remove(_ links: [ViewedLinkEntity]) async throws(ViewedLinkErrorEntity)
    /// Remove a link matched by its URL.
    func removeUnavailable(linkURL: URL) async throws(ViewedLinkErrorEntity)
    /// Remove every viewed link.
    func clearHistory() async throws(ViewedLinkErrorEntity)
    /// Emits whenever the history changes, so observers can re-fetch.
    func changesSignalSequence() -> AnyAsyncSequence<Void>
}
