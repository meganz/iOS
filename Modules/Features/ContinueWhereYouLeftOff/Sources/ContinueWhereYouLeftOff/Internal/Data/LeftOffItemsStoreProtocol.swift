import MEGADomain

package protocol LeftOffItemsStoreProtocol: Sendable {
    func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool, limit: Int) async throws -> [LeftOffItemEntity]
    func record(_ item: LeftOffItemEntity) async throws
    func remove(handles: [HandleEntity]) async throws
    func removeUnavailable(handle: HandleEntity) async throws
    func clearHistory() async throws
}
