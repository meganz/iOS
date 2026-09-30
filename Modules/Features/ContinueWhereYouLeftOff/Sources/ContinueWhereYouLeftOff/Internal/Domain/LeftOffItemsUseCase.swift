import Foundation
import MEGADomain
import MEGASwift

package struct LeftOffItemsUseCase: LeftOffItemsUseCaseProtocol {
    private static let maxStoredItems = 50
    private static let maxConcurrentNodeLookups = 3
    private static let maxTopItemsFetchAttempts = 5

    private let repository: any LeftOffItemsRepositoryProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol

    package init(
        repository: some LeftOffItemsRepositoryProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol
    ) {
        self.repository = repository
        self.nodeUseCase = nodeUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }

    package func items(
        sortedBy key: LeftOffItemsSortKey,
        ascending: Bool
    ) async throws(LeftOffItemErrorEntity) -> [ResolvedLeftOffItemEntity] {
        guard nodeUseCase.rootNode() != nil else { return [] }
        return try await fetchBatch(sortedBy: key, ascending: ascending, limit: Self.maxStoredItems).items
    }

    package func topItems(limit: Int) async throws(LeftOffItemErrorEntity) -> [ResolvedLeftOffItemEntity] {
        guard nodeUseCase.rootNode() != nil else { return [] }
        guard limit > 0 else { return [] }
        var result: [ResolvedLeftOffItemEntity] = []
        // For topItems fetch, there could be a case where rows are pruned due to unavailability
        // or being hidden. In such case we need to attempt to re-fetch so
        // we can possibly get the final output of `limit` items.
        for _ in 0..<Self.maxTopItemsFetchAttempts {
            let fetched = try await fetchBatch(sortedBy: .lastAccessed, ascending: false, limit: limit)
            result = fetched.items
            // a fetch with `storedCount < limit` means that we reach the end of the store
            // no need to retry
            guard fetched.prunedCount > 0, fetched.storedCount == limit else { break }
        }
        return result
    }

    package func record(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity) {
        try await repository.record(item)
    }

    package func remove(_ items: [LeftOffItemEntity]) async throws(LeftOffItemErrorEntity) {
        try await repository.remove(items)
    }

    package func removeUnavailable(_ item: LeftOffItemEntity) async throws(LeftOffItemErrorEntity) {
        try await repository.removeUnavailable(handle: item.handle)
    }

    package func clearHistory() async throws(LeftOffItemErrorEntity) {
        try await repository.clearHistory()
    }

    package func changesSignalSequence() -> AnyAsyncSequence<Void> {
        // [IOS-12121] - Combine with store change
        nodeUseCase.nodeUpdates
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }

    private func fetchBatch(
        sortedBy key: LeftOffItemsSortKey,
        ascending: Bool,
        limit: Int
    ) async throws(LeftOffItemErrorEntity) -> FetchResultBatch {
        let stored = try await repository.fetchItems(sortedBy: key, ascending: ascending, limit: limit)
        let filtered = try await resolvedAndFiltered(stored)
        guard key == .name else {
            return FetchResultBatch(items: filtered.items, storedCount: stored.count, prunedCount: filtered.prunedCount)
        }
        let sorted = filtered.items.sorted {
            let order = $0.item.name.localizedStandardCompare($1.item.name)
            return ascending ? order == .orderedAscending : order == .orderedDescending
        }
        return FetchResultBatch(items: sorted, storedCount: stored.count, prunedCount: filtered.prunedCount)
    }

    private func resolvedAndFiltered(
        _ items: [LeftOffItemEntity]
    ) async throws(LeftOffItemErrorEntity) -> (items: [ResolvedLeftOffItemEntity], prunedCount: Int) {
        let sensitivityAccessible = sensitiveNodeUseCase.isAccessible()
        async let excludeSensitivesResult = sensitiveDisplayPreferenceUseCase.excludeSensitives()

        let inspected = await items.taskGroup(maxConcurrentTasks: Self.maxConcurrentNodeLookups) { item in
            await inspect(item, checkingSensitivity: sensitivityAccessible)
        }
        guard !Task.isCancelled else { throw .cancelled }

        let byHandle = Dictionary(inspected.map { ($0.item.handle, $0) }, uniquingKeysWith: { first, _ in first })
        let excludeSensitives = await excludeSensitivesResult

        var result: [ResolvedLeftOffItemEntity] = []
        var prunedCount = 0
        for item in items {
            guard let entry = byHandle[item.handle] else { continue }
            guard let node = entry.node, !entry.isUnavailable else {
                try await repository.removeUnavailable(handle: item.handle)
                prunedCount += 1
                continue
            }
            // By design, we remove the items from store if they're hidden
            if excludeSensitives && entry.isSensitive {
                try await repository.removeUnavailable(handle: item.handle)
                prunedCount += 1
                continue
            }
            result.append(item.resolved(from: node, isSensitive: entry.isSensitive))
        }
        return (result, prunedCount)
    }

    private func inspect(_ item: LeftOffItemEntity, checkingSensitivity: Bool) async -> InspectedLeftOffItem {
        guard let node = await nodeUseCase.nodeForHandle(item.handle) else {
            return InspectedLeftOffItem(item: item, node: nil, isUnavailable: true, isSensitive: false)
        }
        guard !nodeUseCase.isInRubbishBin(nodeHandle: node.handle) else {
            return InspectedLeftOffItem(item: item, node: node, isUnavailable: true, isSensitive: false)
        }
        guard checkingSensitivity else {
            return InspectedLeftOffItem(item: item, node: node, isUnavailable: false, isSensitive: false)
        }
        let inherited = (try? await sensitiveNodeUseCase.isInheritingSensitivity(node: node)) == true
        return InspectedLeftOffItem(
            item: item,
            node: node,
            isUnavailable: false,
            isSensitive: node.isMarkedSensitive || inherited
        )
    }
}

private struct FetchResultBatch {
    let items: [ResolvedLeftOffItemEntity]
    let storedCount: Int
    let prunedCount: Int
}

private struct InspectedLeftOffItem: Sendable {
    let item: LeftOffItemEntity
    let node: NodeEntity?
    let isUnavailable: Bool
    let isSensitive: Bool
}

private extension LeftOffItemEntity {
    /// Map to a `ResolvedLeftOffItemEntity`, refreshing `name` and filling `duration` (seconds, when positive)
    /// and `isSensitive` from the resolved live node. A blank live name keeps the stored one.
    func resolved(from node: NodeEntity, isSensitive: Bool) -> ResolvedLeftOffItemEntity {
        ResolvedLeftOffItemEntity(
            item: LeftOffItemEntity(handle: handle, name: node.name.isEmpty ? name : node.name, lastAccessed: lastAccessed),
            duration: node.duration > 0 ? TimeInterval(node.duration) : nil,
            isSensitive: isSensitive
        )
    }
}
