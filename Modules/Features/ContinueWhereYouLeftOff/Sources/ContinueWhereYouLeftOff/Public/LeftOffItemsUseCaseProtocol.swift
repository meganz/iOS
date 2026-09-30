import MEGADomain
import MEGASwift

public protocol LeftOffItemsUseCaseProtocol: Sendable {
    /// Fetch all items, sorted by the given key and direction.
    /// Sensitive nodes are checked
    /// prune dead rows
    /// Map resolved rows to `ResolvedLeftOffItemEntity` with the data
    func items(sortedBy key: LeftOffItemsSortKey, ascending: Bool) async throws(LeftOffItemErrorEntity) -> [ResolvedLeftOffItemEntity]

    /// The most recently accessed items, capped at `limit`.
    func topItems(limit: Int) async throws(LeftOffItemErrorEntity) -> [ResolvedLeftOffItemEntity]

    /// Upsert an item, keyed by handle.
    func record(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity)

    /// Remove the given items.
    func remove(_ items: [LeftOffItemEntity]) async throws(LeftOffItemErrorEntity)

    /// Remove a single item whose live node can no longer be resolved or opened.
    func removeUnavailable(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity)

    /// Clear all left-off items.
    func clearHistory() async throws(LeftOffItemErrorEntity)

    /// Emits a signal whenever something that can change the resolved list happens
    func changesSignalSequence() -> AnyAsyncSequence<Void>
}
