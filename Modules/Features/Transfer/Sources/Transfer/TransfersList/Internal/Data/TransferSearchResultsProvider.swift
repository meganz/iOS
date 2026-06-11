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
    private let locationResolver: any TransferLocationResolving
    private let filteringUserTransfers: Bool
    private let clearTransfersUseCase: any ClearTransfersUseCaseProtocol

    private let cachedResultIds: Atomic<[ResultId]> = Atomic(wrappedValue: [])

    init(
        filter: Filter,
        inventoryUseCase: some TransferInventoryUseCaseProtocol,
        counterUseCase: some TransferCounterUseCaseProtocol,
        registry: TransferRegistry,
        locationResolver: some TransferLocationResolving,
        filteringUserTransfers: Bool = true,
        clearTransfersUseCase: some ClearTransfersUseCaseProtocol
    ) {
        self.filter = filter
        self.inventoryUseCase = inventoryUseCase
        self.counterUseCase = counterUseCase
        self.registry = registry
        self.locationResolver = locationResolver
        self.filteringUserTransfers = filteringUserTransfers
        self.clearTransfersUseCase = clearTransfersUseCase
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
        merge(
            merge(startSignals(), updateSignals(), finishSignals()),
            clearSignals()
        )
        .eraseToAnyAsyncSequence()
    }

    // MARK: - Snapshot

    private func snapshot() async -> SearchResultsEntity {
        let entities = await currentEntries()
        let results = entities.map(TransferEntityMapper.searchResult)
        let ids = results.map(\.id)
        cachedResultIds.mutate { $0 = ids }
        let states = await rowStates(for: entities)
        let registry = self.registry
        await MainActor.run {
            for state in states {
                registry.upsert(state)
            }
        }
        return SearchResultsEntity(results: results, availableChips: [], appliedChips: [])
    }

    /// Builds row states for a snapshot. Only the Completed tab needs the file
    /// system path, and that path requires an SDK lookup for uploads, so location
    /// is resolved here (off the main actor) rather than in the pure mapper.
    private func rowStates(for entities: [TransferEntity]) async -> [TransferRowState] {
        guard filter == .completed else {
            return entities.map { TransferEntityMapper.rowState(for: $0) }
        }
        var states: [TransferRowState] = []
        states.reserveCapacity(entities.count)
        for entity in entities {
            let location = await locationResolver.location(for: entity)
            states.append(TransferEntityMapper.rowState(for: entity, location: location))
        }
        return states
    }

    private func currentEntries() async -> [TransferEntity] {
        switch filter {
        case .active:
            let all = await inventoryUseCase.transfers(filteringUserTransfers: filteringUserTransfers)
            return all.filter(\.isVisibleInList).filter(Self.isActive)
        case .completed:
            return inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
                .filter(\.isVisibleOnCompletedTab)
        case .failed:
            return inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
                .filter(\.isVisibleOnFailedTab)
        }
    }

    // MARK: - Signal streams

    /// Re-query pings from the bulk-clear action, mapped to a generic re-snapshot.
    /// Clearing is a silent SDK cache removal that fires no transfer delegate event,
    /// so this is the only signal that re-snapshots the list after a clear.
    private func clearSignals() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        clearTransfersUseCase.clearedSignals
            .map { _ in SearchResultUpdateSignal.generic }
            .eraseToAnyAsyncSequence()
    }

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
        let locationResolver = self.locationResolver
        return counterUseCase.transferFinishUpdates
            .compactMap { response -> SearchResultUpdateSignal? in
                let entity = response.transferEntity
                let id = TransferEntityMapper.resultId(for: entity)
                switch filter {
                case .active:
                    await registry.remove(id: id)
                    return .generic
                case .completed where Self.isCompleted(entity):
                    let location = await locationResolver.location(for: entity)
                    await registry.upsert(TransferEntityMapper.rowState(for: entity, location: location))
                    return .generic
                case .failed where Self.isFailed(entity):
                    await registry.upsert(TransferEntityMapper.rowState(for: entity))
                    return .generic
                default:
                    return nil
                }
            }
            .eraseToAnyAsyncSequence()
    }

    // MARK: - State classification

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
