import ContinueWhereYouLeftOff
import MEGADomain
import MEGASwift

/// Mock `LeftOffItemsStoreProtocol` for repository tests. Surfaces raw errors (untyped `throws`),
/// mirroring the real store, so the repository's error mapping can be exercised.
package final class MockLeftOffItemsStore: LeftOffItemsStoreProtocol, @unchecked Sendable {
    package var fetchItemsResult: [LeftOffItemEntity]
    package var errorToThrow: (any Error)?
    package var changesSignalSequenceResult: AnyAsyncSequence<Void> =
        AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()

    package private(set) var recordedItems: [LeftOffItemEntity] = []
    package private(set) var removedHandles: [[HandleEntity]] = []
    package private(set) var removedUnavailableHandles: [HandleEntity] = []
    package private(set) var clearHistoryCallCount = 0
    package private(set) var lastSortKey: LeftOffItemsSortKey?
    package private(set) var lastAscending: Bool?
    package private(set) var lastLimit: Int?

    package init(
        fetchItemsResult: [LeftOffItemEntity] = [],
        errorToThrow: (any Error)? = nil
    ) {
        self.fetchItemsResult = fetchItemsResult
        self.errorToThrow = errorToThrow
    }

    package func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool, limit: Int) async throws -> [LeftOffItemEntity] {
        lastSortKey = key
        lastAscending = ascending
        lastLimit = limit
        if let errorToThrow { throw errorToThrow }
        return fetchItemsResult
    }

    package func record(_ item: LeftOffItemEntity) async throws {
        if let errorToThrow { throw errorToThrow }
        recordedItems.append(item)
    }

    package func remove(handles: [HandleEntity]) async throws {
        if let errorToThrow { throw errorToThrow }
        removedHandles.append(handles)
    }

    package func removeUnavailable(handle: HandleEntity) async throws {
        if let errorToThrow { throw errorToThrow }
        removedUnavailableHandles.append(handle)
    }

    package func clearHistory() async throws {
        if let errorToThrow { throw errorToThrow }
        clearHistoryCallCount += 1
    }

    package func changesSignalSequence() -> AnyAsyncSequence<Void> {
        changesSignalSequenceResult
    }
}
