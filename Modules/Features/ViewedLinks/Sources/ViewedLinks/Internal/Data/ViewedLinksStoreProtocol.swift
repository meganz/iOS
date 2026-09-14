import Foundation
import MEGASwift

/// Raw data-source contract over the SwiftData stack. Wrapped by
/// `ViewedLinksRepository`; consumed only inside the module, hence `package`.
/// Untyped `async throws`: it surfaces raw `NSError` / `CancellationError`, and
/// the repository is the single boundary that maps those to `ViewedLinkErrorEntity`.
package protocol ViewedLinksStoreProtocol: Sendable {
    func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws -> [ViewedLinkEntity]
    func topViewedLinks(limit: Int) async throws -> [ViewedLinkEntity]
    func record(_ link: ViewedLinkEntity) async throws
    func remove(_ links: [ViewedLinkEntity]) async throws
    func removeUnavailable(linkURL: URL) async throws
    func clearHistory() async throws

    /// Emits once per persisted mutation, driving the v1 re-fetch refresh.
    /// Never finishes on its own; consumers cancel the iterating task when done.
    func changesSignalSequence() -> AnyAsyncSequence<Void>
}
