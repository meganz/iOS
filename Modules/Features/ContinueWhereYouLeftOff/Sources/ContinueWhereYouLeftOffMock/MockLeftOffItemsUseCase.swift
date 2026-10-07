import ContinueWhereYouLeftOff
import Foundation
import MEGASwift

/// Mock `LeftOffItemsUseCaseProtocol` for tests and previews.
public final class MockLeftOffItemsUseCase: LeftOffItemsUseCaseProtocol, @unchecked Sendable {
    public var itemsResult: [ResolvedLeftOffItemEntity]
    public var topItemsResult: [ResolvedLeftOffItemEntity]
    public var errorToThrow: LeftOffItemErrorEntity?
    public var topItemsResultsPerCall: [[ResolvedLeftOffItemEntity]] = []
    public var topItemsErrorsPerCall: [LeftOffItemErrorEntity?] = []
    public var onTopItems: (@Sendable (Int) async -> Void)?
    public var changesSignalSequenceResult: AnyAsyncSequence<Void> =
        AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()

    public private(set) var recordedItems: [LeftOffItemEntity] = []
    public private(set) var removedItems: [[LeftOffItemEntity]] = []
    public private(set) var removedUnavailableItems: [LeftOffItemEntity] = []
    public private(set) var clearHistoryCallCount = 0
    public private(set) var lastSortKey: LeftOffItemsSortKey?
    public private(set) var lastAscending: Bool?
    public private(set) var lastTopLimit: Int?

    public var recordCallCount: Int { recordedItems.count }
    public var topItemsCallCount: Int { lock.withLock { topItemsCalls } }

    private let lock = NSLock()
    private var topItemsCalls = 0

    public init(
        itemsResult: [ResolvedLeftOffItemEntity] = [],
        topItemsResult: [ResolvedLeftOffItemEntity] = [],
        errorToThrow: LeftOffItemErrorEntity? = nil
    ) {
        self.itemsResult = itemsResult
        self.topItemsResult = topItemsResult
        self.errorToThrow = errorToThrow
    }

    public func items(sortedBy key: LeftOffItemsSortKey, ascending: Bool) async throws(LeftOffItemErrorEntity) -> [ResolvedLeftOffItemEntity] {
        lastSortKey = key
        lastAscending = ascending
        if let errorToThrow { throw errorToThrow }
        return itemsResult
    }

    public func topItems(limit: Int) async throws(LeftOffItemErrorEntity) -> [ResolvedLeftOffItemEntity] {
        lastTopLimit = limit
        let call = lock.withLock {
            topItemsCalls += 1
            return topItemsCalls
        }
        await onTopItems?(call)
        if call <= topItemsErrorsPerCall.count, let error = topItemsErrorsPerCall[call - 1] { throw error }
        if let errorToThrow { throw errorToThrow }
        if call <= topItemsResultsPerCall.count { return topItemsResultsPerCall[call - 1] }
        return Array(topItemsResult.prefix(limit))
    }

    public func record(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        recordedItems.append(item)
    }

    public func remove(_ items: [LeftOffItemEntity]) async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        removedItems.append(items)
    }

    public func removeUnavailable(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        removedUnavailableItems.append(item)
    }

    public func clearHistory() async throws(LeftOffItemErrorEntity) {
        if let errorToThrow { throw errorToThrow }
        clearHistoryCallCount += 1
    }

    public func changesSignalSequence() -> AnyAsyncSequence<Void> {
        changesSignalSequenceResult
    }
}
