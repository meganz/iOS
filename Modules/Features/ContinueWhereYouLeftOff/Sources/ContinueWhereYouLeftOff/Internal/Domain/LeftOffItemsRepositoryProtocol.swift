import MEGADomain

package protocol LeftOffItemsRepositoryProtocol: Sendable {
    func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool, limit: Int) async throws(LeftOffItemErrorEntity) -> [LeftOffItemEntity]
    func record(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity)
    func remove(_ items: [LeftOffItemEntity]) async throws(LeftOffItemErrorEntity)
    func removeUnavailable(handle: HandleEntity) async throws(LeftOffItemErrorEntity)
    func clearHistory() async throws(LeftOffItemErrorEntity)
}
