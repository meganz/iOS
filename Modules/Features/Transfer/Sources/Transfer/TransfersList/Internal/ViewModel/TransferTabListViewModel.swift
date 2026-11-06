import Combine
import Foundation
import MEGAAppSDKRepo
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
///
/// Active lists its rows in transfer-queue order (see `TransferQueuePosition`) and
/// lets the user drag them to reprioritise; the other tabs list in arrival order.
@MainActor
final class TransferTabListViewModel: ObservableObject {
    typealias FlushPublisherThrottle = (AnyPublisher<Void, Never>) -> AnyPublisher<Void, Never>
    typealias SearchPublisherDebounce = (AnyPublisher<String, Never>) -> AnyPublisher<String, Never>

    /// The rows on screen: the tab's rows narrowed to the settled search query.
    @Published private(set) var rows: [TransferRowViewModel] = []

    /// Active only: the download queue's rows, listed before the uploads.
    var downloadRows: [TransferRowViewModel] {
        rows.filter { $0.transfer.type != .upload }
    }

    /// Active only: the upload queue's rows, listed after the downloads.
    var uploadRows: [TransferRowViewModel] {
        rows.filter { $0.transfer.type == .upload }
    }

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
    /// Active only: each listed row's queue position; `orderedIds` is kept sorted by it.
    private var queuePositions: [Int: TransferQueuePosition] = [:]
    /// Active only: the priority a dragged row had before the drag, until the SDK
    /// reports another. An update still carrying it predates the move, so it must not
    /// put the row back where it was.
    private var prereorderPriorities: [Int: UInt64] = [:]
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
        guard tab.isQueueOrdered else {
            if presentIds.insert(state.id).inserted {
                orderedIds.append(state.id)
                scheduleFlush()
            }
            return
        }
        if presentIds.insert(state.id).inserted {
            let position = TransferQueuePosition(entity)
            queuePositions[state.id] = position
            orderedIds.insert(state.id, at: insertionIndex(for: position))
            scheduleFlush()
        } else if let position = reconcileQueuePosition(of: entity), move(id: state.id, to: position) {
            // The SDK reprioritised the transfer: a drag-reorder landing, or the
            // neighbours it renumbers when there is no room left between two rows.
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
            for id in removedIds {
                queuePositions[id] = nil
                prereorderPriorities[id] = nil
            }
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
        queuePositions.removeAll()
        prereorderPriorities.removeAll()
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
        if tab.isQueueOrdered {
            orderSnapshot(entities)
        }
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

    /// Sorts a fresh Active snapshot into queue order. A dragged row the SDK has not
    /// moved yet keeps the place it was dropped in.
    private func orderSnapshot(_ entities: [TransferEntity]) {
        var positions: [Int: TransferQueuePosition] = [:]
        for entity in entities {
            positions[entity.tag] = reconcileQueuePosition(of: entity)
                ?? queuePositions[entity.tag]
                ?? TransferQueuePosition(entity)
        }
        queuePositions = positions
        prereorderPriorities = prereorderPriorities.filter { positions[$0.key] != nil }
        orderedIds = positions.values.sorted().map(\.tag)
    }

    // MARK: - Reorder

    /// Applies a drag within one queue of the Active tab and returns the move for
    /// `commitReorder(_:)` to send to the SDK, or `nil` when the queue order is unchanged.
    /// Offsets are within `queue`'s rows.
    ///
    /// `rows` shows the drop exactly as the list made it: publishing any other order in
    /// the same pass leaves a blank slot where the row was. Rows that finished meanwhile
    /// go with the next flush.
    func reorder(in queue: TransferQueue, fromOffsets source: IndexSet, toOffset destination: Int) -> TransferReorder? {
        guard tab.isQueueOrdered, source.count == 1, let sourceIndex = source.first else { return nil }
        var queueRows = queue == .uploads ? uploadRows : downloadRows
        guard queueRows.indices.contains(sourceIndex) else { return nil }
        let movedRow = queueRows[sourceIndex]
        guard let previousPosition = queuePositions[movedRow.id] else { return nil }

        let currentIds = listedIds(queueRows)
        queueRows.move(fromOffsets: source, toOffset: destination)
        rows = queue == .uploads ? downloadRows + queueRows : queueRows + uploadRows
        let droppedIds = listedIds(queueRows)
        guard droppedIds != currentIds, let index = droppedIds.firstIndex(of: movedRow.id) else { return nil }

        let previousId = index > 0 ? droppedIds[index - 1] : nil
        let nextId = index + 1 < droppedIds.count ? droppedIds[index + 1] : nil
        let provisionalPosition = TransferQueuePosition(
            isUpload: previousPosition.isUpload,
            priority: provisionalPriority(
                after: previousId.flatMap { queuePositions[$0]?.priority },
                before: nextId.flatMap { queuePositions[$0]?.priority }
            ),
            tag: movedRow.id
        )
        // Kept from an earlier drag the SDK hasn't applied yet: that one is still the
        // priority stale updates carry.
        prereorderPriorities[movedRow.id] = prereorderPriorities[movedRow.id] ?? previousPosition.priority
        move(id: movedRow.id, to: provisionalPosition)

        return TransferReorder(
            transfer: movedRow.transfer,
            nextTransfer: nextId.flatMap { dependency.registry.rowViewModel(for: $0)?.transfer },
            previousPosition: previousPosition,
            provisionalPosition: provisionalPosition
        )
    }

    /// Sends a drag-reorder to the SDK, and puts the row back if the SDK rejects it.
    /// On success the SDK reports the priority it assigned as a transfer update.
    func commitReorder(_ reorder: TransferReorder) async {
        do {
            if let nextTransfer = reorder.nextTransfer {
                try await dependency.controlUseCase.moveTransfer(reorder.transfer, before: nextTransfer)
            } else {
                try await dependency.controlUseCase.moveTransferToEnd(reorder.transfer)
            }
        } catch {
            MEGALogError("[Transfer] reorder failed for tag \(reorder.transfer.tag): \(error)")
            let id = reorder.transfer.tag
            prereorderPriorities[id] = nil
            // Left alone if it finished meanwhile or a later drag has moved it again.
            guard presentIds.contains(id), queuePositions[id] == reorder.provisionalPosition else { return }
            move(id: id, to: reorder.previousPosition)
            flush()
        }
    }

    // MARK: - Queue order

    /// The rows' ids, leaving out rows that finished but stay on screen until the next
    /// flush: the SDK can no longer move them or move anything before them.
    private func listedIds(_ queueRows: [TransferRowViewModel]) -> [Int] {
        queueRows.map(\.id).filter { presentIds.contains($0) }
    }

    /// A priority between the new neighbours', so the row sorts where it was dropped
    /// until the SDK reports the one it assigned.
    private func provisionalPriority(after previous: UInt64?, before next: UInt64?) -> UInt64 {
        switch (previous, next) {
        case let (previous?, next?): previous + (next - previous) / 2
        case let (nil, next?): next > 0 ? next - 1 : 0
        case let (previous?, nil): previous + 1
        case (nil, nil): 0
        }
    }

    /// The entity's queue position, or `nil` while it still reports the priority it
    /// had before the user dragged it. Once a new priority arrives, the drag is settled
    /// and its pre-drag priority is forgotten.
    private func reconcileQueuePosition(of entity: TransferEntity) -> TransferQueuePosition? {
        if let prereorderPriority = prereorderPriorities[entity.tag] {
            guard entity.priority != prereorderPriority else { return nil }
            prereorderPriorities[entity.tag] = nil
        }
        return TransferQueuePosition(entity)
    }

    /// Moves a listed row to where `position` sorts. `false` when it is already there.
    @discardableResult
    private func move(id: Int, to position: TransferQueuePosition) -> Bool {
        guard queuePositions[id] != position else { return false }
        queuePositions[id] = position
        if let index = orderedIds.firstIndex(of: id) {
            orderedIds.remove(at: index)
        }
        orderedIds.insert(id, at: insertionIndex(for: position))
        return true
    }

    /// Binary search over `orderedIds`, which Active keeps sorted by queue position.
    private func insertionIndex(for position: TransferQueuePosition) -> Int {
        var low = 0
        var high = orderedIds.count
        while low < high {
            let middle = (low + high) / 2
            if let middlePosition = queuePositions[orderedIds[middle]], position < middlePosition {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return low
    }
}
