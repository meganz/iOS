import ContinueWhereYouLeftOff
import MEGADomain

/// Mock `LeftOffItemsRepositoryProtocol` for use-case tests.
package final class MockLeftOffItemsRepository: LeftOffItemsRepositoryProtocol, @unchecked Sendable {
    package var fetchItemsResult: [LeftOffItemEntity]
    package var errorToThrow: LeftOffItemErrorEntity?

    package private(set) var recordedItems: [LeftOffItemEntity] = []
    package private(set) var removedItems: [[LeftOffItemEntity]] = []
    package private(set) var removedUnavailableHandles: [HandleEntity] = []
    package private(set) var clearHistoryCallCount = 0
    package private(set) var lastSortKey: LeftOffItemsSortKey?
    package private(set) var lastAscending: Bool?

    package init(
        fetchItemsResult: [LeftOffItemEntity] = [],
        errorToThrow: LeftOffItemErrorEntity? = nil
    ) {
        self.fetchItemsResult = fetchItemsResult
        self.errorToThrow = errorToThrow
    }

    package func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool) async throws(LeftOffItemErrorEntity) -> [LeftOffItemEntity] {
        lastSortKey = key
        lastAscending = ascending
        if let errorToThrow { throw errorToThrow }
        return fetchItemsResult
    }

    package func record(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        recordedItems.append(item)
    }

    package func remove(_ items: [LeftOffItemEntity]) async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        removedItems.append(items)
    }

    package func removeUnavailable(handle: HandleEntity) async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        removedUnavailableHandles.append(handle)
    }

    package func clearHistory() async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        clearHistoryCallCount += 1
    }
}
