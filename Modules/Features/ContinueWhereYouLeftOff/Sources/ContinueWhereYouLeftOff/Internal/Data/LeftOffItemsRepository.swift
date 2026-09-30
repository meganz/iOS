import MEGADomain
import MEGAFoundation

package struct LeftOffItemsRepository: LeftOffItemsRepositoryProtocol {
    private let store: any LeftOffItemsStoreProtocol

    package init(store: some LeftOffItemsStoreProtocol) {
        self.store = store
    }

    package func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool, limit: Int) async throws(LeftOffItemErrorEntity) -> [LeftOffItemEntity] {
        try await perform { try await store.fetchItems(sortedBy: key, ascending: ascending, limit: limit) }
    }

    package func record(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity) {
        try await perform { try await store.record(item) }
    }

    package func remove(_ items: [LeftOffItemEntity]) async throws(LeftOffItemErrorEntity) {
        try await perform { try await store.remove(handles: items.map(\.handle)) }
    }

    package func removeUnavailable(handle: HandleEntity) async throws(LeftOffItemErrorEntity) {
        try await perform { try await store.removeUnavailable(handle: handle) }
    }

    package func clearHistory() async throws(LeftOffItemErrorEntity) {
        try await perform { try await store.clearHistory() }
    }

    private func perform<T>(_ operation: () async throws -> T) async throws(LeftOffItemErrorEntity) -> T {
        do {
            return try await operation()
        } catch is CancellationError {
            throw .cancelled
        } catch {
            MEGALog.log(level: .error, message: "[ContinueWhereYouLeftOff] Persistence operation failed: \(error)")
            throw .persistenceFailure
        }
    }
}
