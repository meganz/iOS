import ContinueWhereYouLeftOff
import MEGADomain
import MEGASwift

/// Mock `LeftOffItemsRepositoryProtocol` for use-case tests.
package final class MockLeftOffItemsRepository: LeftOffItemsRepositoryProtocol, @unchecked Sendable {
    package var fetchItemsResult: [LeftOffItemEntity]
    /// When non-empty, each `fetchItems` call returns the next batch (clamped to the last one),
    /// so tests can drive the `topItems` retry loop across changing store contents.
    package var fetchItemsBatches: [[LeftOffItemEntity]] = []
    package var errorToThrow: LeftOffItemErrorEntity?
    package var changesSignalSequenceResult: AnyAsyncSequence<Void> =
        AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()

    package private(set) var fetchItemsCallCount = 0
    package private(set) var recordedItems: [LeftOffItemEntity] = []
    package private(set) var removedItems: [[LeftOffItemEntity]] = []
    package private(set) var removedUnavailableHandles: [HandleEntity] = []
    package private(set) var clearHistoryCallCount = 0
    package private(set) var lastSortKey: LeftOffItemsSortKey?
    package private(set) var lastAscending: Bool?
    package private(set) var lastLimit: Int?

    package init(
        fetchItemsResult: [LeftOffItemEntity] = [],
        errorToThrow: LeftOffItemErrorEntity? = nil
    ) {
        self.fetchItemsResult = fetchItemsResult
        self.errorToThrow = errorToThrow
    }

    package func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool, limit: Int) async throws(LeftOffItemErrorEntity) -> [LeftOffItemEntity] {
        lastSortKey = key
        lastAscending = ascending
        lastLimit = limit
        fetchItemsCallCount += 1
        if let errorToThrow { throw errorToThrow }
        guard !fetchItemsBatches.isEmpty else { return fetchItemsResult }
        let index = min(fetchItemsCallCount - 1, fetchItemsBatches.count - 1)
        return fetchItemsBatches[index]
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

    package func changesSignalSequence() -> AnyAsyncSequence<Void> {
        changesSignalSequenceResult
    }
}
