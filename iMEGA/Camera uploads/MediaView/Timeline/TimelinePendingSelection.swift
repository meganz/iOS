import Combine
import ContentLibraries
import Foundation
import MEGADomain
import MEGASwift
import SwiftUI

/// A selected cell the timeline has no node for yet, addressed the way the layout addresses it: a
/// day bucket and an offset inside it, under the query that produced them. A flat index would name
/// a different cell as soon as a bucket above it resized.
struct TimelineSelectionSlot: Hashable, Sendable {
    let queryGeneration: Int
    let groupId: String
    let localOffset: Int
}

/// What one selection-driven hydration produced, as far as the retry budget is concerned.
enum TimelineSelectionHydrationOutcome {
    /// Fetched and published, so whatever it covered has been answered.
    case committed
    /// The query answered and those positions are still blank.
    case unproductive
    /// Thrown away before it could answer — it says nothing about the positions it covered.
    case discarded
}

/// What the pending selection needs from the timeline: the layout it is pointing at, and a way to
/// fetch a stretch of it.
@MainActor
protocol TimelineSelectionResolving: AnyObject {
    var selectionProjection: TimelineProjection { get }
    var selectionQueryGeneration: Int { get }
    func hydrateForSelection(_ range: Range<Int>) async -> TimelineSelectionHydrationOutcome
}

/// The half of the timeline's selection that is still a position rather than a node.
///
/// A grid keys selection by handle, and a cell whose photo has not loaded has none, so its mark is
/// held here as a coordinate until a query says what sits there — at which point it moves, once and
/// for good, into ``PhotoSelection``. Every coordinate in the feature lives in this one type, which
/// is what lets a reshape sweep them all in a single pass.
///
/// It is also the producer of the layout version: nothing else bumps it, so a screen without one of
/// these keeps the behaviour it has today.
@MainActor
final class TimelinePendingSelection: PositionalSelectionHandling {
    /// Marked positions with no node yet. Disjoint from `selection.photos` — a slot crosses over
    /// exactly once, when its photo lands.
    private(set) var unresolvedSlots: Set<TimelineSelectionSlot> = []

    /// What the count has to add to the committed selection.
    var unresolvedCount: Int { unresolvedSlots.count }

    /// Committed nodes plus marks, as one number.
    @Published private(set) var markedCount = 0

    var markedCountPublisher: AnyPublisher<Int, Never> {
        $markedCount.eraseToAnyPublisher()
    }

    /// Stamped onto every library the grid renders, so a position read off a screen that has since
    /// been re-laid out is refused rather than answered about whatever moved into it.
    private(set) var layoutVersion = PhotoLibrary.initialLayoutVersion

    weak var resolver: (any TimelineSelectionResolving)?

    /// Unproductive attempts per slot: a position the SDK never fills would otherwise be retried
    /// for the rest of the edit session. Rejections are not attempts and never land here.
    private var resolutionFailureCounts: [TimelineSelectionSlot: Int] = [:]
    private var gestureBaselines: [SelectionGestureToken: GestureBaseline] = [:]
    private var longPressed: LongPressMark?

    /// The committed half's size, taken from its publisher: `@Published` announces a change before
    /// storing it, so reading `selection.photos` while handling one gives the count it is leaving.
    private var committedCount = 0

    /// Set while marks are crossing into the committed selection, which takes several writes.
    private var isMigrating = false

    /// Bumped by every teardown, so a cycle on its way back cannot touch what replaced it.
    private var selectionSession = 0

    /// A reshape mutates inside the timeline's commit transaction, where the library and the
    /// sections it is read against have not both been swapped yet. Telling the cells there would
    /// have them ask a position question of half a layout, so the answer waits for the last step of
    /// that transaction — ``promoteResolvedSlots()``.
    private var changedDuringReshape = false
    private var settleTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var resolutionTask: Task<Void, Never>?

    private let selection: PhotoSelection
    private let settleInterval: Duration
    private let selectionDidChange = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()

    /// Consecutive unproductive attempts a slot is given before it is dropped.
    private static let maxResolutionFailures = 3
    private static let recentLongPressWindow: TimeInterval = 0.7

    /// One wait per retry, so there is one fewer than the attempts a slot is given: the last
    /// unproductive attempt drops it rather than arming another. 100 ms then 300 ms in production —
    /// a region the SDK never fills must not be re-asked at the settle interval all session.
    private var retryDelays: [Duration] {
        [settleInterval, settleInterval * 3]
    }

    /// What one drag started from. Both halves: a band runs over loaded photos and blank slots
    /// alike, and a slot resolving mid-drag moves a cell from the second half to the first.
    private struct GestureBaseline {
        var handles: Set<HandleEntity>
        var slots: Set<TimelineSelectionSlot>
    }

    /// The cell a long press just marked, under whichever name it has. A blank cell acquires a
    /// handle partway through the window, and the drag that follows the same unlifted finger asks
    /// under the name the *grid* has for it — which is a debounce behind. So both are kept, and the
    /// window runs from the press either way.
    private struct LongPressMark {
        var slot: TimelineSelectionSlot?
        var handle: HandleEntity?
        let at: Date

        func isRecent(within window: TimeInterval) -> Bool {
            Date().timeIntervalSince(at) < window
        }
    }

    init(selection: PhotoSelection, settleInterval: Duration = .milliseconds(100)) {
        self.selection = selection
        self.settleInterval = settleInterval
        // The committed half's size arrives with its changes, never by reading it back.
        selection.$photos
            .sink { [weak self] photos in
                guard let self else { return }
                committedCount = photos.count
                publishMarkedCount()
            }
            .store(in: &subscriptions)
        // Leaving edit mode is the one place selection is cleared; the committed half is cleared by
        // `PhotoSelection`'s own edit-mode flow, and this is the rest of it.
        selection.$editMode
            .map(\.isEditing)
            .removeDuplicates()
            .dropFirst()
            .filter { !$0 }
            .sink { [weak self] _ in self?.teardown() }
            .store(in: &subscriptions)
    }

    // MARK: - The timeline's side

    /// A reshape is being published. Runs inside ``NewTimelineViewModel``'s commit transaction, so
    /// the new version, the sections it describes and the library reach the screen together.
    func layoutDidReshape(
        to sections: [MediaDateSectionEntity], countDeltas: [String: Int], newestFirst: Bool
    ) {
        layoutVersion &+= 1
        let generation = resolver?.selectionQueryGeneration ?? 0
        let newCounts = Dictionary(uniqueKeysWithValues: sections.map { ($0.groupId, $0.count) })
        // Where a slot sits after this reshape, or nil when its bucket can no longer hold it.
        let rebased: (TimelineSelectionSlot) -> TimelineSelectionSlot? = { slot in
            guard slot.queryGeneration == generation,
                  let count = newCounts[slot.groupId] else { return nil }
            let delta = countDeltas[slot.groupId] ?? 0
            let offset = slot.localOffset + ((delta > 0 && newestFirst) ? delta : 0)
            guard (0..<count).contains(offset) else { return nil }
            return TimelineSelectionSlot(
                queryGeneration: slot.queryGeneration, groupId: slot.groupId, localOffset: offset)
        }

        // Everything positional in one sweep. The handles a drag started from are deliberately not
        // swept: a handle names the same photo in any layout, and the drag goes on being answered
        // for its loaded cells until the grid catches up and ends it.
        let kept = Set(unresolvedSlots.compactMap(rebased))
        for (token, baseline) in Array(gestureBaselines) {
            gestureBaselines[token]?.slots = Set(baseline.slots.compactMap(rebased))
        }
        if let slot = longPressed?.slot {
            // Cleared rather than left slotless: a mark under neither name answers for nothing, and
            // the drag following the same finger would read its own origin cell as one to toggle.
            if let moved = rebased(slot) { longPressed?.slot = moved } else { longPressed = nil }
        }
        // Moved with their slots. Left where they were, a mark that outlived a reshape would
        // inherit a stranger's budget and could be dropped on failures that were never its own.
        var movedFailureCounts: [TimelineSelectionSlot: Int] = [:]
        for (slot, failures) in resolutionFailureCounts {
            guard let moved = rebased(slot), kept.contains(moved) else { continue }
            movedFailureCounts[moved] = failures
        }
        resolutionFailureCounts = movedFailureCounts
        guard kept != unresolvedSlots else { return }
        unresolvedSlots = kept
        publishMarkedCount()
        changedDuringReshape = true
    }

    /// Commit every mark whose position now holds a real node.
    func promoteResolvedSlots() {
        defer {
            isMigrating = false
            if changedDuringReshape { notifyChanged() } else { publishMarkedCount() }
        }
        guard let resolver else { return }
        // Every record that names a cell by position, not only the marks still standing: a cell the
        // drag has just unmarked still has to restore correctly if the band shrinks back over it.
        var positional = unresolvedSlots
        for baseline in gestureBaselines.values { positional.formUnion(baseline.slots) }
        if let slot = longPressed?.slot { positional.insert(slot) }
        guard positional.isNotEmpty else { return }

        let projection = resolver.selectionProjection
        var resolved: [TimelineSelectionSlot: NodeEntity] = [:]
        for slot in positional {
            guard let index = flatIndex(of: slot, in: projection),
                  let node = projection.hydratedNode(at: index) else { continue }
            resolved[slot] = node
        }
        guard resolved.isNotEmpty else { return }

        // The same cells, under names that survive a reshape.
        for (token, baseline) in Array(gestureBaselines) {
            var updated = baseline
            for (slot, node) in resolved where baseline.slots.contains(slot) {
                updated.slots.remove(slot)
                updated.handles.insert(node.handle)
            }
            gestureBaselines[token] = updated
        }
        if let mark = longPressed, let slot = mark.slot, let node = resolved[slot] {
            longPressed?.slot = nil
            longPressed?.handle = node.handle
            // The grid may already be drawing the photo, in which case the drag will ask
            // `PhotoSelection` for the mark instead — dated from the press, not from here.
            selection.markRecentlyLongPressed(node.handle, at: mark.at)
        }

        var committed = false
        isMigrating = true
        for (slot, node) in resolved where unresolvedSlots.contains(slot) {
            selection.selectPhoto(node)
            unresolvedSlots.remove(slot)
            resolutionFailureCounts[slot] = nil
            committed = true
        }
        if committed { notifyChanged() }
    }

    /// The query changed. Every position on screen now names a different photo — including the
    /// ones the grid is still showing, and it goes on showing them until the projection built under
    /// the new query is published. Moving the version here is what refuses them in between; the
    /// marks themselves belong to the query that is gone.
    func queryDidChange() {
        layoutVersion &+= 1
        teardown()
    }

    /// Drop every mark and stop every cycle: the user left edit mode, the view went away, or the
    /// query changed under it. In-flight queries may still land; they find nothing to commit.
    func teardown() {
        selectionSession &+= 1
        settleTask = nil
        resolutionTask?.cancel()
        resolutionTask = nil
        gestureBaselines.removeAll()
        longPressed = nil
        resolutionFailureCounts.removeAll()
        guard unresolvedSlots.isNotEmpty else { return }
        unresolvedSlots.removeAll()
        notifyChanged()
    }

    // MARK: - PositionalSelectionHandling

    var selectionDidChangePublisher: AnyPublisher<Void, Never> {
        selectionDidChange.eraseToAnyPublisher()
    }

    /// Whether the cell at `position` is marked.
    func isSelected(at position: SelectionPosition) -> Bool {
        guard let resolver else { return false }
        let projection = resolver.selectionProjection
        guard let slot = slot(at: position.flatIndex, in: projection) else { return false }
        if unresolvedSlots.contains(slot) { return true }
        guard let node = projection.hydratedNode(at: position.flatIndex) else { return false }
        return selection.photos[node.handle] != nil
    }

    func apply(_ interaction: PhotoSelectionInteraction, at position: SelectionPosition) {
        guard position.layoutVersion == layoutVersion, let resolver else { return }
        let projection = resolver.selectionProjection
        guard let slot = slot(at: position.flatIndex, in: projection) else { return }

        // The photo may have landed while the grid was still drawing the placeholder the user
        // touched. The mark then belongs to that node, not to the position it arrived at.
        if let node = projection.hydratedNode(at: position.flatIndex) {
            applyToLoaded(interaction, node)
            if unresolvedSlots.remove(slot) != nil { notifyChanged() }
            return
        }

        let wasPending = unresolvedSlots.contains(slot)
        switch interaction {
        case .tap:
            if wasPending { unresolvedSlots.remove(slot) } else { unresolvedSlots.insert(slot) }
        case .longPress, .dragSelect:
            unresolvedSlots.insert(slot)
        case .dragDeselect:
            unresolvedSlots.remove(slot)
        }
        guard unresolvedSlots.contains(slot) != wasPending else { return }
        // A mark the user just made starts with a full retry budget, whatever the last one spent.
        resolutionFailureCounts[slot] = nil
        notifyChanged()
        restartSettleTimer()
    }

    func beginSelectionGesture() -> SelectionGestureToken {
        let token = SelectionGestureToken()
        gestureBaselines[token] = GestureBaseline(
            handles: Set(selection.photos.keys), slots: unresolvedSlots)
        return token
    }

    func wasSelectedAtGestureStart(_ token: SelectionGestureToken, at position: SelectionPosition) -> Bool {
        guard position.layoutVersion == layoutVersion,
              let baseline = gestureBaselines[token],
              let resolver else { return false }
        let projection = resolver.selectionProjection
        // Asked for a cell the grid still draws blank, which may have acquired its photo — and with
        // it its name in the record — since the drag began.
        if let node = projection.hydratedNode(at: position.flatIndex) {
            return baseline.handles.contains(node.handle)
        }
        guard let slot = slot(at: position.flatIndex, in: projection) else { return false }
        return baseline.slots.contains(slot)
    }

    func wasSelectedAtGestureStart(_ token: SelectionGestureToken, handle: HandleEntity) -> Bool {
        gestureBaselines[token]?.handles.contains(handle) ?? false
    }

    func endSelectionGesture(_ token: SelectionGestureToken) {
        gestureBaselines[token] = nil
    }

    func markRecentlyLongPressed(at position: SelectionPosition) {
        guard position.layoutVersion == layoutVersion, let resolver else { return }
        let projection = resolver.selectionProjection
        // Pressed on a cell the grid draws blank whose photo has already landed: the mark belongs
        // to that node, and has to be readable from the side that keys by handle.
        if let node = projection.hydratedNode(at: position.flatIndex) {
            longPressed = LongPressMark(slot: nil, handle: node.handle, at: Date())
            selection.markRecentlyLongPressed(node.handle)
            return
        }
        guard let slot = slot(at: position.flatIndex, in: projection) else { return }
        longPressed = LongPressMark(slot: slot, handle: nil, at: Date())
    }

    func wasRecentlyLongPressed(at position: SelectionPosition) -> Bool {
        guard position.layoutVersion == layoutVersion, let longPressed, let resolver,
              longPressed.isRecent(within: Self.recentLongPressWindow) else { return false }
        let projection = resolver.selectionProjection
        if let node = projection.hydratedNode(at: position.flatIndex) {
            return longPressed.handle == node.handle
        }
        // Not `==` on two optionals: a mark that has handed over to a handle has no slot left, and
        // neither has a position this layout cannot place.
        guard let slot = slot(at: position.flatIndex, in: projection) else { return false }
        return longPressed.slot == slot
    }

    func consumeRecentLongPressMark() {
        longPressed = nil
        // One mark, kept under two names; consuming it has to reach both.
        selection.consumeRecentLongPressMark()
    }

    // MARK: - Resolution cycle

    /// Any change to the set restarts the timer, so a drag resolves once the finger settles rather
    /// than per cell. `delay` carries the backoff of a retry.
    private func restartSettleTimer(after delay: Duration? = nil) {
        guard unresolvedSlots.isNotEmpty else {
            settleTask = nil
            return
        }
        let session = selectionSession
        let interval = delay ?? settleInterval
        settleTask = Task { [weak self] in
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            self?.startResolutionCycle(session: session)
        }
    }

    /// One cycle at a time. A slot added while one runs is picked up by the next, which the running
    /// cycle arms on its way out.
    private func startResolutionCycle(session: Int) {
        guard session == selectionSession, resolutionTask == nil, unresolvedSlots.isNotEmpty else { return }
        resolutionTask = Task { [weak self] in
            guard let self else { return }
            await runResolutionCycle(session: session)
            guard session == selectionSession else { return }
            resolutionTask = nil
            restartSettleTimer(after: nextRetryDelay())
        }
    }

    private func runResolutionCycle(session: Int) async {
        dropUnresolvableSlots()
        promoteResolvedSlots()
        guard let resolver, unresolvedSlots.isNotEmpty else { return }

        let layoutBefore = layoutVersion
        var unproductive: Set<TimelineSelectionSlot> = []
        for request in requests(for: unresolvedSlots, in: resolver.selectionProjection) {
            guard session == selectionSession, !Task.isCancelled else { return }
            // Each commit promotes what it filled on its way through, so there is nothing to
            // collect here: whatever is still in the set was not answered for.
            if await resolver.hydrateForSelection(request.range) == .unproductive {
                unproductive.formUnion(request.slots)
            }
        }

        // A layout that moved took every reason to charge with it: a batch rejected by a reshape is
        // not a failed query, and letting a busy upload spend the budget would drop a live mark.
        guard session == selectionSession, layoutVersion == layoutBefore else { return }
        charge(unproductive.intersection(unresolvedSlots))
    }

    /// Drop marks the current layout can no longer place: a different query, a day that is gone, or
    /// an offset that would now resolve into the next day.
    private func dropUnresolvableSlots() {
        guard let resolver else { return }
        let projection = resolver.selectionProjection
        let kept = unresolvedSlots.filter { flatIndex(of: $0, in: projection) != nil }
        guard kept != unresolvedSlots else { return }
        unresolvedSlots = kept
        resolutionFailureCounts = resolutionFailureCounts.filter { kept.contains($0.key) }
        notifyChanged()
    }

    private func charge(_ slots: Set<TimelineSelectionSlot>) {
        guard slots.isNotEmpty else { return }
        var dropped: Set<TimelineSelectionSlot> = []
        for slot in slots {
            let failures = (resolutionFailureCounts[slot] ?? 0) + 1
            resolutionFailureCounts[slot] = failures
            guard failures >= Self.maxResolutionFailures else { continue }
            dropped.insert(slot)
            resolutionFailureCounts[slot] = nil
        }
        guard dropped.isNotEmpty else { return }
        MEGALogError("[TimelinePendingSelection] dropped \(dropped.count) selections that never resolved")
        unresolvedSlots.subtract(dropped)
        notifyChanged()
    }

    private func nextRetryDelay() -> Duration? {
        let failures = unresolvedSlots.compactMap { resolutionFailureCounts[$0] }.max() ?? 0
        guard failures > 0 else { return nil }
        return retryDelays[min(failures, retryDelays.count) - 1]
    }

    /// One request per run of adjacent marks. Gaps are not bridged: the hydration path splits a
    /// range into its placeholder runs anyway, and merging across loaded cells would only fetch
    /// neighbours nobody selected.
    private func requests(
        for slots: Set<TimelineSelectionSlot>, in projection: TimelineProjection
    ) -> [(range: Range<Int>, slots: [TimelineSelectionSlot])] {
        let placed = slots
            .compactMap { slot in flatIndex(of: slot, in: projection).map { (index: $0, slot: slot) } }
            .sorted { $0.index < $1.index }
        // Grown through the subscript, never through a copy of the last element: a painted band is
        // one run thousands of cells long, and copying its collection per cell is quadratic — on
        // the main actor, between the finger lifting and the request going out.
        var ranges: [Range<Int>] = []
        var slotsPerRange: [[TimelineSelectionSlot]] = []
        for placement in placed {
            if let last = ranges.indices.last, ranges[last].upperBound == placement.index {
                ranges[last] = ranges[last].lowerBound..<(placement.index + 1)
                slotsPerRange[last].append(placement.slot)
            } else {
                ranges.append(placement.index..<(placement.index + 1))
                slotsPerRange.append([placement.slot])
            }
        }
        return Array(zip(ranges, slotsPerRange)).map { (range: $0.0, slots: $0.1) }
    }

    // MARK: - Positions

    private func applyToLoaded(_ interaction: PhotoSelectionInteraction, _ node: NodeEntity) {
        switch interaction {
        case .tap:
            if selection.photos[node.handle] == nil {
                selection.selectPhoto(node)
            } else {
                selection.deselectPhoto(node)
            }
        case .longPress, .dragSelect:
            selection.selectPhoto(node)
        case .dragDeselect:
            selection.deselectPhoto(node)
        }
    }

    private func slot(at flatIndex: Int, in projection: TimelineProjection) -> TimelineSelectionSlot? {
        guard let generation = resolver?.selectionQueryGeneration,
              let anchor = projection.sectionAnchor(forFlatIndex: flatIndex) else { return nil }
        return TimelineSelectionSlot(
            queryGeneration: generation,
            groupId: anchor.section.groupId,
            localOffset: anchor.localOffset)
    }

    /// Where a slot sits now, or nil when this layout can no longer place it. Resolving it back to
    /// its own bucket is the whole of the validity check: an offset past the end of a day, or a day
    /// that is gone, lands somewhere else or nowhere.
    private func flatIndex(of slot: TimelineSelectionSlot, in projection: TimelineProjection) -> Int? {
        guard slot.queryGeneration == resolver?.selectionQueryGeneration,
              let index = projection.flatIndex(
                of: .init(groupId: slot.groupId, localOffset: slot.localOffset)),
              projection.sectionAnchor(forFlatIndex: index)?.section.groupId == slot.groupId else { return nil }
        return index
    }

    private func notifyChanged() {
        changedDuringReshape = false
        publishMarkedCount()
        selectionDidChange.send(())
    }

    private func publishMarkedCount() {
        guard !isMigrating else { return }
        let total = committedCount + unresolvedSlots.count
        guard total != markedCount else { return }
        markedCount = total
    }
}
