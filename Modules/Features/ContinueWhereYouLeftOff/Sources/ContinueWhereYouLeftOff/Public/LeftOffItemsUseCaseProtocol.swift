import MEGADomain
import MEGASwift

public protocol LeftOffItemsUseCaseProtocol: Sendable {
    /// Fetch all items, sorted by the given key and direction.
    /// Resolves each row's live node to filter hidden/sensitive nodes,
    /// prune dead rows, refresh metadata and fill the video's `duration`.
    func items(sortedBy key: LeftOffItemsSortKey, ascending: Bool) async throws(LeftOffItemErrorEntity) -> [LeftOffItemEntity]

    /// The most recently accessed items, capped at `limit`.
    func topItems(limit: Int) async throws(LeftOffItemErrorEntity) -> [LeftOffItemEntity]

    /// Upsert an item, keyed by handle.
    func record(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity)

    /// Remove the given items.
    func remove(_ items: [LeftOffItemEntity]) async throws(LeftOffItemErrorEntity)

    /// Remove a single item whose live node can no longer be resolved or opened.
    func removeUnavailable(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity)

    /// Clear all left-off items.
    func clearHistory() async throws(LeftOffItemErrorEntity)

    /// Live stream of the left-off items, re-emitted whenever the underlying nodes change.
    /// Each emission is fully resolved, the same as `items(sortedBy:ascending:)`.
    func leftOffItemsUpdates() -> AnyAsyncSequence<[LeftOffItemEntity]>
}
