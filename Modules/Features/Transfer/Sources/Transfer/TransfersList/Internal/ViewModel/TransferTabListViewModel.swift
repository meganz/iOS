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
    typealias SearchPublisherDebounce = (AnyPublisher<String, Never>) -> AnyPublisher<String, Never>

    /// The rows on screen: the tab's rows narrowed to the settled search query.
    @Published private(set) var rows: [TransferRowViewModel] = []

    /// Whether the tab has any rows before the search filter applies. Tells the
    /// tab's own empty state apart from a search that matched nothing.
    @Published private(set) var hasTransfers = false

    /// `false` until the initial snapshot lands, so the empty state doesn't flash
    /// before the first rows appear.
    @Published private(set) var isLoaded = false

    /// Filters the rows by file name (case-insensitive substring) on searchable tabs,
    /// once typing pauses: filtering runs on the main actor, so it isn't redone per keystroke.
    @Published var searchText: String {
        didSet {
            guard searchText != oldValue else { return }
            onSearchTextChanged(searchText)
        }
    }

    /// The query `rows` is currently filtered by.
    private var appliedSearchText: String
    private var searchCancellable: AnyCancellable?

    /// Reports query changes up to the screen, which keeps each tab's query
    /// across the re-creation of this view model on a tab switch.
    private let onSearchTextChanged: @MainActor (String) -> Void

    /// Select-mode selection, shared with the screen. This view model keeps its
    /// `listedTags` in step with the rows the tab lists; the removal path does so
    /// synchronously (never behind the flush throttle) so a selected row that
    /// finishes stops counting in the same frame.
    private let selection: TransferSelection

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
        selection: TransferSelection = TransferSelection(),
        searchText: String = "",
        onSearchTextChanged: @escaping @MainActor (String) -> Void = { _ in },
        searchDebounce: SearchPublisherDebounce = {
            $0.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        },
        throttle: @escaping FlushPublisherThrottle = {
            $0.throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
                .eraseToAnyPublisher()
        }
    ) {
        self.tab = tab
        self.dependency = dependency
        self.selection = selection
        self.searchText = searchText
        appliedSearchText = searchText
        self.onSearchTextChanged = onSearchTextChanged
        self.throttle = throttle
        rowStateBuilder = TransferRowStateBuilder(
            tab: tab,
            locationResolver: dependency.locationResolver,
            finishDateProvider: dependency.finishDateProvider
        )
        // The initial query needs no debounce: the snapshot applies it. Clearing
        // skips the debounce too, so the full list comes back right away.
        let queries = $searchText.dropFirst()
        searchCancellable = searchDebounce(queries.eraseToAnyPublisher())
            .merge(with: queries.filter { $0.isEmpty })
            .sink { [weak self] in
                self?.applySearchText($0)
            }
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
        // O(1) and synchronous: the flush below is throttled, and a selected row
        // that just left must drop out of the top-bar count immediately.
        selection.dropListedTag(id)
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
        // Rows inserted since the last flush become selectable here; removals
        // already pruned themselves synchronously.
        publishRows()
    }

    private func applySearchText(_ text: String) {
        guard text != appliedSearchText else { return }
        appliedSearchText = text
        publishRows()
    }

    /// Re-derives the on-screen rows from `orderedIds` and the applied search query.
    private func publishRows() {
        let tabRows = orderedIds.compactMap { dependency.registry.rowViewModel(for: $0) }
        let query = tab.isSearchable ? appliedSearchText.trimmingCharacters(in: .whitespaces) : ""
        hasTransfers = !tabRows.isEmpty
        rows = query.isEmpty
            ? tabRows
            : tabRows.filter { $0.state.fileName.localizedCaseInsensitiveContains(query) }
        // Derived from `rows`, not `presentIds`: the selectable set has to be
        // exactly what is on screen, or select-all and the count drift apart.
        selection.setListedTags(Set(rows.map(\.id)))
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
        // A re-snapshot (e.g. after a clear) can drop rows wholesale; this also
        // converges the selection on what is now listed.
        publishRows()
        isLoaded = true
    }
}
