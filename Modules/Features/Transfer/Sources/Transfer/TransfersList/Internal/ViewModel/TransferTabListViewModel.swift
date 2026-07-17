import Combine
import Foundation
import MEGADomain

/// Owns the list for a single Transfers tab.
///
/// The inventory is snapshotted once per mount; after that, transfer events
/// are applied incrementally, and the two kinds of change take different paths:
/// - **Progress** mutates the matching `TransferRowViewModel` in place: only the
///   observing row re-renders, `rows` is untouched.
/// - **Membership** (a row appearing or leaving) is buffered and its publish is
///   throttled: the first change lands immediately, then bursts publish at most
///   once per interval, so N finish events cost one list diff, not N.
@MainActor
final class TransferTabListViewModel: ObservableObject {
    typealias FlushPublisherThrottle = (AnyPublisher<Void, Never>) -> AnyPublisher<Void, Never>

    @Published private(set) var rows: [TransferRowViewModel] = []

    /// `false` until the initial snapshot lands, so the empty state doesn't flash
    /// before the first rows appear.
    @Published private(set) var isLoaded = false

    private let tab: TransfersTab
    private let dependency: TransferTabDependency
    private let throttle: FlushPublisherThrottle
    private let rowStateBuilder: TransferRowStateBuilder

    private var orderedIds: [Int] = []
    /// The ids this tab currently lists
    private var presentIds: Set<Int> = []
    private var removedIds: Set<Int> = []
    private var finishedIds: Set<Int> = []
    private let flushSignal = PassthroughSubject<Void, Never>()
    private var flushCancellable: AnyCancellable?

    init(
        tab: TransfersTab,
        dependency: TransferTabDependency,
        throttle: @escaping FlushPublisherThrottle = {
            $0.throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
                .eraseToAnyPublisher()
        }
    ) {
        self.tab = tab
        self.dependency = dependency
        self.throttle = throttle
        rowStateBuilder = TransferRowStateBuilder(
            tab: tab,
            locationResolver: dependency.locationResolver,
            finishDateProvider: dependency.finishDateProvider
        )
    }

    /// Subscribes to transfer events, loads the initial snapshot, then
    /// consumes buffered and live events until the owning view disappears.
    func monitorTransferEvents() async {
        let events = dependency.itemsUseCase.events(for: tab)
        flushCancellable = throttle(flushSignal.eraseToAnyPublisher())
            .sink { [weak self] in
                self?.flush()
            }
        defer {
            flushCancellable = nil
            pruneRows()
        }
        await loadSnapshot()
        for await event in events {
            await apply(event)
        }
    }

    // MARK: - Events

    private func apply(_ event: TransferTabEvent) async {
        switch event {
        case .started(let entity):
            guard !finishedIds.contains(entity.tag) else { return }
            // Started/updated events only carry non-terminal states; terminal rows
            // are rebuilt by the finish/snapshot paths with the real policy result.
            upsertRow(TransferEntityMapper.rowState(for: entity, isRetryable: false), entity: entity)
        case .updated(let entity):
            // Mutate-only: an update never inserts, so a stale 100% progress
            // update delivered after the finish cannot resurrect the row.
            guard presentIds.contains(entity.tag) else { return }
            upsertRow(TransferEntityMapper.rowState(for: entity, isRetryable: false), entity: entity)
        case .finished(let entity):
            await applyFinish(entity)
        case .cleared:
            await loadSnapshot()
        }
    }

    private func applyFinish(_ entity: TransferEntity) async {
        switch tab {
        case .active:
            finishedIds.insert(entity.tag)
            removeRow(id: entity.tag)
        case .completed, .failed:
            upsertRow(await rowStateBuilder.finishState(for: entity), entity: entity)
        }
    }

    // MARK: - Row mutations

    private func upsertRow(_ state: TransferRowState, entity: TransferEntity) {
        dependency.registry.upsert(state, transfer: entity)
        if presentIds.insert(state.id).inserted {
            orderedIds.append(state.id)
            scheduleFlush()
        }
    }

    private func removeRow(id: Int) {
        guard presentIds.remove(id) != nil else { return }
        dependency.registry.remove(id: id)
        removedIds.insert(id)
        scheduleFlush()
    }

    private func scheduleFlush() {
        flushSignal.send()
    }

    private func flush() {
        if !removedIds.isEmpty {
            orderedIds.removeAll { removedIds.contains($0) }
            removedIds.removeAll()
        }
        rows = orderedIds.compactMap { dependency.registry.rowViewModel(for: $0) }
    }

    private func pruneRows() {
        for id in presentIds {
            dependency.registry.remove(id: id)
        }
        presentIds.removeAll()
    }

    // MARK: - Snapshot

    private func loadSnapshot() async {
        let entities = await dependency.itemsUseCase.snapshot(for: tab)
        let states = await rowStateBuilder.snapshotStates(for: entities)
        let registry = dependency.registry
        let previousIds = presentIds
        for (state, entity) in zip(states, entities) {
            registry.upsert(state, transfer: entity)
        }
        orderedIds = states.map(\.id)
        presentIds = Set(orderedIds)
        removedIds.removeAll()
        finishedIds.removeAll()
        // Rows this tab rendered that vanished from the snapshot (e.g. after a
        // clear) would leave stale view models in the shared registry.
        for id in previousIds.subtracting(presentIds) {
            registry.remove(id: id)
        }
        rows = orderedIds.compactMap { registry.rowViewModel(for: $0) }
        isLoaded = true
    }
}
