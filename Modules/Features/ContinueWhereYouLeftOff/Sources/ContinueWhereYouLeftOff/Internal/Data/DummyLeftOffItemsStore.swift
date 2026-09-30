import MEGADomain

// Temporary store, will be replaced with actual SwiftData implementation
package struct DummyLeftOffItemsStore: LeftOffItemsStoreProtocol {
    package init() {}

    package func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool, limit: Int) async throws -> [LeftOffItemEntity] { [] }
    package func record(_ item: LeftOffItemEntity) async throws {}
    package func remove(handles: [HandleEntity]) async throws {}
    package func removeUnavailable(handle: HandleEntity) async throws {}
    package func clearHistory() async throws {}
}
