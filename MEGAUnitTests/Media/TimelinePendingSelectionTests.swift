import Combine
import ContentLibraries
import Foundation
@testable import MEGA
import MEGADomain
import SwiftUI
import Testing

/// The half of the selection that is still a position. These drive it directly, with a stand-in for
/// the timeline: what the layout is, and what a fetch of a stretch of it produced.
@MainActor
@Suite("Timeline pending selection")
struct TimelinePendingSelectionTests {
    private static let firstDay = Date(timeIntervalSince1970: 1_660_780_800)  // 2022-08-18T00:00:00Z
    private static let secondDay = Date(timeIntervalSince1970: 1_658_102_400) // 2022-07-18T00:00:00Z

    /// Two day buckets of 2 and 3 slots: flat indices 0...1 sit in `2022-08-18`, 2...4 in `2022-07-18`.
    private static func sections(first: Int = 2, second: Int = 3) -> [MediaDateSectionEntity] {
        var sections: [MediaDateSectionEntity] = []
        if first > 0 {
            sections.append(.init(
                groupId: "2022-08-18", startDate: firstDay, endDate: firstDay, count: first))
        }
        if second > 0 {
            sections.append(.init(
                groupId: "2022-07-18", startDate: secondDay, endDate: secondDay, count: second))
        }
        return sections
    }

    private static func projection(
        _ sections: [MediaDateSectionEntity], hydrating replacements: [Int: NodeEntity] = [:]
    ) -> TimelineProjection {
        let skeleton = TimelineProjection(
            library: PhotoLibrary.skeleton(from: sections), sections: sections, hydratedCoordinates: [:])
        var coordinates: [HandleEntity: TimelineProjection.BucketCoordinate] = [:]
        for (index, node) in replacements {
            guard let anchor = skeleton.sectionAnchor(forFlatIndex: index) else { continue }
            coordinates[node.handle] = .init(
                groupId: anchor.section.groupId, localOffset: anchor.localOffset)
        }
        return TimelineProjection(
            library: skeleton.library.replacingPhotos(at: replacements),
            sections: sections,
            hydratedCoordinates: coordinates)
    }

    private struct SUT {
        let pendingSelection: TimelinePendingSelection
        let resolver: MockTimelineSelectionResolver
        let selection: PhotoSelection
    }

    /// The settle interval is the unit the retry backoff is measured in, so a millisecond here is
    /// the whole cycle — timer, request, backoff — at a thousandth of its production pace.
    private static func makeSUT(
        hydrating replacements: [Int: NodeEntity] = [:],
        sections: [MediaDateSectionEntity]? = nil,
        settleInterval: Duration = .milliseconds(1)
    ) -> SUT {
        let selection = PhotoLibraryContentViewModel(library: PhotoLibrary()).selection
        let resolver = MockTimelineSelectionResolver(
            projection: projection(sections ?? Self.sections(), hydrating: replacements))
        let pendingSelection = TimelinePendingSelection(
            selection: selection, settleInterval: settleInterval)
        pendingSelection.resolver = resolver
        selection.editMode = .active
        return SUT(pendingSelection: pendingSelection, resolver: resolver, selection: selection)
    }

    private static func position(_ flatIndex: Int, layoutVersion: Int = 0) -> SelectionPosition {
        SelectionPosition(flatIndex: flatIndex, layoutVersion: layoutVersion)
    }

    /// Give the settle timer and the cycle it starts room to run, without pinning the test to how
    /// many hops that takes.
    private static func waitUntil(_ isSatisfied: () -> Bool) async {
        for _ in 0..<100 {
            if isSatisfied() { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Marking

    @Test("Tapping a cell with no photo yet marks it, and tapping it again clears the mark")
    func tapTogglesAMark() {
        let sut = Self.makeSUT()

        sut.pendingSelection.apply(.tap, at: Self.position(0))
        #expect(sut.pendingSelection.unresolvedCount == 1)
        #expect(sut.pendingSelection.isSelected(at: Self.position(0)))
        #expect(sut.selection.photos.isEmpty) // nothing to commit: there is no node

        sut.pendingSelection.apply(.tap, at: Self.position(0))
        #expect(sut.pendingSelection.unresolvedCount == 0)
        #expect(!sut.pendingSelection.isSelected(at: Self.position(0)))
    }

    @Test("A drag marks and unmarks the cells it runs over")
    func dragSelectAndDeselect() {
        let sut = Self.makeSUT()

        sut.pendingSelection.apply(.dragSelect, at: Self.position(0))
        sut.pendingSelection.apply(.dragSelect, at: Self.position(1))
        #expect(sut.pendingSelection.unresolvedCount == 2)

        sut.pendingSelection.apply(.dragDeselect, at: Self.position(1))
        #expect(sut.pendingSelection.unresolvedCount == 1)
    }

    @Test("An interaction read off a layout that has been replaced is ignored, not guessed at")
    func staleLayoutVersionIsRefused() {
        let sut = Self.makeSUT()
        sut.pendingSelection.layoutDidReshape(
            to: Self.sections(first: 3), bucketsWhoseCountChanged: ["2022-08-18"])
        sut.resolver.projection = Self.projection(Self.sections(first: 3))

        sut.pendingSelection.apply(.tap, at: Self.position(0, layoutVersion: 0))

        #expect(sut.pendingSelection.unresolvedCount == 0)
        // The same tap against the version now on screen does land.
        sut.pendingSelection.apply(.tap, at: Self.position(0, layoutVersion: 1))
        #expect(sut.pendingSelection.unresolvedCount == 1)
    }

    @Test("A tap on a cell whose photo landed while the grid was behind selects that photo")
    func tapOnAPositionThatHasSinceLoaded() {
        let node = NodeEntity(name: "a.jpg", handle: 7)
        let sut = Self.makeSUT(hydrating: [0: node])

        sut.pendingSelection.apply(.tap, at: Self.position(0))

        #expect(sut.selection.photos[7] == node)
        #expect(sut.pendingSelection.unresolvedCount == 0)
    }

    // MARK: - Reshape

    @Test("A reshape drops the marks in the bucket that resized and keeps the rest")
    func reshapeDiscardsMarksInTheResizedBucket() {
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(0)) // 2022-08-18
        sut.pendingSelection.apply(.tap, at: Self.position(3)) // 2022-07-18

        sut.pendingSelection.layoutDidReshape(
            to: Self.sections(first: 3), bucketsWhoseCountChanged: ["2022-08-18"])
        sut.resolver.projection = Self.projection(Self.sections(first: 3))

        #expect(sut.pendingSelection.unresolvedCount == 1)
        // One slot lower in the new layout, and it is still the same cell of the same day.
        #expect(sut.pendingSelection.isSelected(at: Self.position(4, layoutVersion: 1)))
    }

    @Test("A mark whose day is gone goes with it")
    func reshapeDropsAMarkWhoseBucketVanished() {
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(3)) // 2022-07-18

        sut.pendingSelection.layoutDidReshape(
            to: Self.sections(second: 0), bucketsWhoseCountChanged: [])

        #expect(sut.pendingSelection.unresolvedCount == 0)
    }

    @Test("A query change refuses the positions on screen before the new layout has been built")
    func queryChangeRefusesTheOldLayoutImmediately() {
        // The grid goes on showing the old layout while the new skeleton is assembled. A tap on it
        // would otherwise be read as a position under the new query — the same day, the same
        // offset, a different photo.
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(0))

        sut.pendingSelection.queryDidChange()

        #expect(sut.pendingSelection.unresolvedCount == 0) // the old query's marks went with it
        sut.pendingSelection.apply(.tap, at: Self.position(0, layoutVersion: 0))
        #expect(sut.pendingSelection.unresolvedCount == 0)
    }

    @Test("Every reshape moves the layout version, so the grid's positions are checked against it")
    func reshapeMovesTheLayoutVersion() {
        let sut = Self.makeSUT()
        #expect(sut.pendingSelection.layoutVersion == PhotoLibrary.initialLayoutVersion)

        sut.pendingSelection.layoutDidReshape(to: Self.sections(), bucketsWhoseCountChanged: [])

        #expect(sut.pendingSelection.layoutVersion == PhotoLibrary.initialLayoutVersion + 1)
    }

    // MARK: - Promotion

    @Test("A mark is pinned to its photo the moment that photo arrives under it")
    func promotionCommitsAResolvedMark() {
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(0))

        let node = NodeEntity(name: "a.jpg", handle: 7)
        sut.resolver.projection = Self.projection(Self.sections(), hydrating: [0: node])
        sut.pendingSelection.promoteResolvedSlots()

        #expect(sut.selection.photos[7] == node)
        #expect(sut.pendingSelection.unresolvedCount == 0) // the count does not move: it crossed over
    }

    @Test("A mark crossing into the selection never publishes a total that was never true")
    func promotionPublishesOneTotal() {
        // The mark leaves one half and joins the other in the same transaction. Published as two
        // changes, the moment in between reads as one more item than was ever selected.
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(0))
        var totals: [Int] = []
        let subscription = sut.pendingSelection.markedCountPublisher.sink { totals.append($0) }

        let node = NodeEntity(name: "a.jpg", handle: 7)
        sut.resolver.projection = Self.projection(Self.sections(), hydrating: [0: node])
        sut.pendingSelection.promoteResolvedSlots()
        subscription.cancel()

        #expect(sut.selection.photos[7] == node) // it did cross over
        #expect(totals == [1]) // the value on subscribe, and nothing after it
    }

    @Test("Selecting a loaded photo and marking a blank cell add up to one count")
    func bothHalvesReachTheSameCount() {
        let node = NodeEntity(name: "a.jpg", handle: 7)
        let sut = Self.makeSUT(hydrating: [4: node])

        sut.selection.selectPhoto(node)
        #expect(sut.pendingSelection.markedCount == 1)

        sut.pendingSelection.apply(.tap, at: Self.position(0))
        #expect(sut.pendingSelection.markedCount == 2)

        sut.selection.deselectPhoto(node)
        #expect(sut.pendingSelection.markedCount == 1)
    }

    @Test("A cell marked before a drag keeps its mark when its photo lands mid-drag")
    func promotionCarriesTheDragBaseline() {
        // Shrink-back asks by handle for a loaded cell, and this cell had no handle when the drag
        // began. Only this side sees it acquire one, so it is the side that has to record it.
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(0))
        let token = sut.pendingSelection.beginSelectionGesture()

        let node = NodeEntity(name: "a.jpg", handle: 7)
        sut.resolver.projection = Self.projection(Self.sections(), hydrating: [0: node])
        sut.pendingSelection.promoteResolvedSlots()

        #expect(sut.pendingSelection.wasSelectedAtGestureStart(token, handle: 7))
        #expect(!sut.pendingSelection.wasSelectedAtGestureStart(token, handle: 99))
    }

    @Test("A cell the drag has unmarked is still restored correctly once its photo lands")
    func promotionCarriesTheBaselineOfAnUnmarkedCell() {
        // The record of what the drag started from is not the record of what is marked now. This
        // cell was marked when the drag began, the drag has since unmarked it, and its photo
        // arrives while the finger is still down — shrinking back over it must mark it again.
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(0))
        let token = sut.pendingSelection.beginSelectionGesture()
        sut.pendingSelection.apply(.dragDeselect, at: Self.position(0))

        let node = NodeEntity(name: "a.jpg", handle: 7)
        sut.resolver.projection = Self.projection(Self.sections(), hydrating: [0: node])
        sut.pendingSelection.promoteResolvedSlots()

        #expect(sut.pendingSelection.wasSelectedAtGestureStart(token, handle: 7))
        // And under the name the grid still has for it, a debounce behind.
        #expect(sut.pendingSelection.wasSelectedAtGestureStart(token, at: Self.position(0)))
    }

    @Test("A cell marked by a long press keeps the drag that follows from toggling it off")
    func longPressMarkSurvivesIntoTheDrag() {
        let sut = Self.makeSUT()

        sut.pendingSelection.apply(.longPress, at: Self.position(1))
        sut.pendingSelection.markRecentlyLongPressed(at: Self.position(1))

        #expect(sut.pendingSelection.wasRecentlyLongPressed(at: Self.position(1)))
        #expect(!sut.pendingSelection.wasRecentlyLongPressed(at: Self.position(0)))
        sut.pendingSelection.consumeRecentLongPressMark()
        #expect(!sut.pendingSelection.wasRecentlyLongPressed(at: Self.position(1)))
    }

    @Test("A long-press mark follows its cell into the committed selection when the photo lands")
    func longPressMarkIsCarriedToTheHandle() {
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.longPress, at: Self.position(0))
        sut.pendingSelection.markRecentlyLongPressed(at: Self.position(0))

        let node = NodeEntity(name: "a.jpg", handle: 7)
        sut.resolver.projection = Self.projection(Self.sections(), hydrating: [0: node])
        sut.pendingSelection.promoteResolvedSlots()

        #expect(sut.selection.wasRecentlyLongPressed(7))
    }

    @Test("A long-press mark is readable under both names while the grid catches up")
    func longPressMarkIsReadableUnderBothNames() {
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.longPress, at: Self.position(0))
        sut.pendingSelection.markRecentlyLongPressed(at: Self.position(0))

        let node = NodeEntity(name: "a.jpg", handle: 7)
        sut.resolver.projection = Self.projection(Self.sections(), hydrating: [0: node])
        sut.pendingSelection.promoteResolvedSlots()

        // The drag that follows the same unlifted finger asks the way the cell renders, and the
        // grid is a debounce behind: both have to answer, or it toggles the press straight off.
        #expect(sut.pendingSelection.wasRecentlyLongPressed(at: Self.position(0)))
        #expect(sut.selection.wasRecentlyLongPressed(7))
    }

    @Test("Long-pressing a cell whose photo has landed marks the photo, not the position")
    func longPressOnAPositionThatHasSinceLoaded() {
        let node = NodeEntity(name: "a.jpg", handle: 7)
        let sut = Self.makeSUT(hydrating: [0: node])

        sut.pendingSelection.apply(.longPress, at: Self.position(0))
        sut.pendingSelection.markRecentlyLongPressed(at: Self.position(0))

        #expect(sut.selection.photos[7] == node)
        // Readable from either side: the grid may catch up before the finger moves.
        #expect(sut.selection.wasRecentlyLongPressed(7))
        #expect(sut.pendingSelection.wasRecentlyLongPressed(at: Self.position(0)))
    }

    // MARK: - Resolution cycle

    @Test("Marks settle into one request per run of adjacent cells, and none for a gap")
    func settleRequestsOneRangePerRun() async {
        let sut = Self.makeSUT()

        sut.pendingSelection.apply(.dragSelect, at: Self.position(0))
        sut.pendingSelection.apply(.dragSelect, at: Self.position(1))
        sut.pendingSelection.apply(.dragSelect, at: Self.position(3))
        await Self.waitUntil { sut.resolver.requestedRanges.count >= 2 }

        #expect(sut.resolver.requestedRanges.prefix(2) == [0..<2, 3..<4])
    }

    @Test("A band of marks is one request, however long the band is")
    func aLongRunMergesIntoOneRequest() async {
        let sut = Self.makeSUT(sections: Self.sections(first: 4_000, second: 0))

        for index in 0..<4_000 {
            sut.pendingSelection.apply(.dragSelect, at: Self.position(index))
        }
        await Self.waitUntil { !sut.resolver.requestedRanges.isEmpty }

        #expect(sut.resolver.requestedRanges.first == 0..<4_000)
    }

    @Test("A run of marks is asked for once, not once per cell, however the drag arrived at it")
    func aDragDoesNotRequestWhileItIsStillMoving() async {
        let sut = Self.makeSUT(settleInterval: .milliseconds(80))

        for index in 0..<5 {
            sut.pendingSelection.apply(.dragSelect, at: Self.position(index))
            try? await Task.sleep(for: .milliseconds(10))
        }
        await Self.waitUntil { !sut.resolver.requestedRanges.isEmpty }

        // Each mark restarted the timer, so nothing was asked for until the drag settled.
        #expect(sut.resolver.requestedRanges.first == 0..<5)
    }

    @Test("A position the query keeps answering blank is given up on, rather than asked for forever")
    func threeUnproductiveAttemptsDropTheMark() async {
        let sut = Self.makeSUT()
        sut.resolver.outcome = .unproductive

        sut.pendingSelection.apply(.tap, at: Self.position(0))
        await Self.waitUntil { sut.pendingSelection.unresolvedCount == 0 }

        #expect(sut.pendingSelection.unresolvedCount == 0)
        #expect(sut.resolver.requestedRanges.count == 3) // and not a fourth
    }

    @Test("A mark the user makes again starts over with a full retry budget")
    func remarkingResetsTheRetryBudget() async {
        let sut = Self.makeSUT()
        sut.resolver.outcome = .unproductive
        sut.pendingSelection.apply(.tap, at: Self.position(0))
        await Self.waitUntil { sut.pendingSelection.unresolvedCount == 0 }

        sut.pendingSelection.apply(.tap, at: Self.position(0))
        await Self.waitUntil { sut.resolver.requestedRanges.count >= 6 }

        #expect(sut.resolver.requestedRanges.count == 6) // three attempts, then three more
    }

    @Test("An attempt thrown away by a reshape costs the mark nothing")
    func aDiscardedAttemptIsNotCharged() async {
        let sut = Self.makeSUT()
        sut.resolver.outcome = .discarded

        sut.pendingSelection.apply(.tap, at: Self.position(0))
        await Self.waitUntil { sut.resolver.requestedRanges.count >= 4 }

        // Still being retried well past the three an unproductive answer would have cost it.
        #expect(sut.pendingSelection.unresolvedCount == 1)
    }

    @Test("A reshape during a cycle voids what that cycle could have been charged for")
    func aReshapeMidCycleVoidsAttribution() async {
        let sut = Self.makeSUT()
        sut.resolver.outcome = .unproductive
        sut.resolver.onHydrate = { [pendingSelection = sut.pendingSelection] _ in
            pendingSelection.layoutDidReshape(to: Self.sections(), bucketsWhoseCountChanged: [])
        }

        sut.pendingSelection.apply(.tap, at: Self.position(0))
        await Self.waitUntil { sut.resolver.requestedRanges.count >= 4 }

        #expect(sut.pendingSelection.unresolvedCount == 1)
    }

    // MARK: - Teardown

    @Test("Leaving edit mode clears the marks and stops the cycle")
    func leavingEditModeTearsDown() async {
        let sut = Self.makeSUT()
        sut.pendingSelection.apply(.tap, at: Self.position(0))

        sut.selection.editMode = .inactive
        #expect(sut.pendingSelection.unresolvedCount == 0)

        try? await Task.sleep(for: .milliseconds(50))
        #expect(sut.resolver.requestedRanges.isEmpty)
    }
}

@MainActor
final class MockTimelineSelectionResolver: TimelineSelectionResolving {
    var projection: TimelineProjection
    var selectionQueryGeneration = 0
    var outcome: TimelineSelectionHydrationOutcome = .committed
    var onHydrate: ((Range<Int>) -> Void)?
    private(set) var requestedRanges: [Range<Int>] = []

    var selectionProjection: TimelineProjection { projection }

    init(projection: TimelineProjection) {
        self.projection = projection
    }

    func hydrateForSelection(_ range: Range<Int>) async -> TimelineSelectionHydrationOutcome {
        requestedRanges.append(range)
        onHydrate?(range)
        return outcome
    }
}
