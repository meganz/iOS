import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGASwift
import Search

/// Adapter that bridges the Transfer domain (`TransferInventoryUseCase` for the
/// initial snapshot and `TransferCounterUseCase` for live SDK delegate streams)
/// into the `Search` package's `SearchResultsProviding` pipeline.
///
/// One instance per tab, parameterised by `Filter`. The exposed update sequence
/// is built lazily by merging the relevant delegate streams and applying
/// per-event registry mutations inside `compactMap`. No task is owned by the
/// provider — the Search VM owns the consumer task via `.task` on the view, so
/// cancellation propagates naturally when the screen disappears.
final class TransferSearchResultsProvider: SearchResultsProviding, Sendable {

    enum Filter: Sendable {
        case active
        case completed
        case failed
    }

    private let filter: Filter
    private let inventoryUseCase: any TransferInventoryUseCaseProtocol
    private let counterUseCase: any TransferCounterUseCaseProtocol
    private let registry: TransferRegistry
    private let filteringUserTransfers: Bool

    private let cachedResultIds: Atomic<[ResultId]> = Atomic(wrappedValue: [])

    init(
        filter: Filter,
        inventoryUseCase: some TransferInventoryUseCaseProtocol,
        counterUseCase: some TransferCounterUseCaseProtocol,
        registry: TransferRegistry,
        filteringUserTransfers: Bool = true
    ) {
        self.filter = filter
        self.inventoryUseCase = inventoryUseCase
        self.counterUseCase = counterUseCase
        self.registry = registry
        self.filteringUserTransfers = filteringUserTransfers
    }

    // MARK: - SearchResultsProviding

    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        await snapshot()
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        guard lastItemIndex == nil else { return nil }
        return await snapshot()
    }

    func currentResultIds() -> [ResultId] {
        cachedResultIds.wrappedValue
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        merge(startSignals(), updateSignals(), finishSignals())
            .eraseToAnyAsyncSequence()
    }

    // MARK: - Snapshot

    private func snapshot() async -> SearchResultsEntity {
        let entities = await currentEntries()
        let results = entities.map(TransferEntityMapper.searchResult)
        let ids = results.map(\.id)
        cachedResultIds.mutate { $0 = ids }
        let registry = self.registry
        await MainActor.run {
            for entity in entities {
                registry.upsert(TransferEntityMapper.rowState(for: entity))
            }
        }
        return SearchResultsEntity(results: results, availableChips: [], appliedChips: [])
    }

    private func currentEntries() async -> [TransferEntity] {
        switch filter {
        case .active:
            let all = await inventoryUseCase.transfers(filteringUserTransfers: filteringUserTransfers)
            return all.filter(Self.isVisibleInList).filter(Self.isActive)
        case .completed:
            return inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
                .filter(Self.isVisibleInList).filter(Self.isCompleted)
        case .failed:
            return inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
                .filter(Self.isVisibleInList).filter(Self.isFailed)
        }
    }

    // MARK: - Signal streams

    private func startSignals() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        let filter = self.filter
        let registry = self.registry
        return counterUseCase.transferStartUpdates
            .compactMap { entity -> SearchResultUpdateSignal? in
                guard filter == .active else { return nil }
                let state = TransferEntityMapper.rowState(for: entity)
                await registry.upsert(state)
                return .generic
            }
            .eraseToAnyAsyncSequence()
    }

    private func updateSignals() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        let filter = self.filter
        let registry = self.registry
        let progress = counterUseCase.transferUpdates
        let temporaryError = counterUseCase.transferTemporaryErrorUpdates.map(\.transferEntity)
        return merge(progress, temporaryError)
            .compactMap { entity -> SearchResultUpdateSignal? in
                guard filter == .active, Self.isActive(entity) else { return nil }
                let state = TransferEntityMapper.rowState(for: entity)
                await registry.upsert(state)
                return .specific(result: TransferEntityMapper.searchResult(for: entity))
            }
            .eraseToAnyAsyncSequence()
    }

    private func finishSignals() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        let filter = self.filter
        let registry = self.registry
        return counterUseCase.transferFinishUpdates
            .compactMap { response -> SearchResultUpdateSignal? in
                let entity = response.transferEntity
                let id = TransferEntityMapper.resultId(for: entity)
                switch filter {
                case .active:
                    await registry.remove(id: id)
                    return .generic
                case .completed where Self.isCompleted(entity),
                     .failed where Self.isFailed(entity):
                    let state = TransferEntityMapper.rowState(for: entity)
                    await registry.upsert(state)
                    return .generic
                default:
                    return nil
                }
            }
            .eraseToAnyAsyncSequence()
    }

    // MARK: - State classification

    /// Folder and streaming transfers are excluded so the snapshot stays in sync
    /// with `TransferCounterUseCase`, which filters them out of its delegate
    /// streams. 
    private static func isVisibleInList(_ entity: TransferEntity) -> Bool {
        !entity.isFolderTransfer && !entity.isStreamingTransfer
    }

    private static func isActive(_ entity: TransferEntity) -> Bool {
        switch entity.state {
        case .none, .queued, .active, .paused, .retrying, .completing: true
        case .complete, .cancelled, .failed: false
        }
    }

    private static func isCompleted(_ entity: TransferEntity) -> Bool {
        entity.state == .complete
    }

    private static func isFailed(_ entity: TransferEntity) -> Bool {
        entity.state == .failed || entity.state == .cancelled
    }
}
