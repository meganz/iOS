@testable import ContentLibraries
import Foundation
import MEGADomain
import Testing
import UIKit

@Suite("PhotoSection changedItemIndexPaths Tests")
struct PhotoSection_changedItemIndexPathsTests {

    private static let august18 = Date(timeIntervalSince1970: 1_660_780_800) // 2022-08-18T00:00:00Z
    private static let august17 = Date(timeIntervalSince1970: 1_660_694_400) // 2022-08-17T00:00:00Z
    private static let july18 = Date(timeIntervalSince1970: 1_658_102_400)   // 2022-07-18T00:00:00Z

    /// A skeleton with two day buckets in different months → day sections sized from `counts`
    /// (default [2, 1] gives sections of 2 and 1 items; flat order [0, 1 | 2]).
    private func makeSkeleton(counts: [Int] = [2, 1]) -> PhotoLibrary {
        makeSkeleton(counts: counts, days: [("2022-08-18", Self.august18), ("2022-07-18", Self.july18)])
    }

    /// A skeleton with two day buckets in the *same* month, so one month section spans both.
    private func makeSameMonthSkeleton(counts: [Int] = [2, 2]) -> PhotoLibrary {
        makeSkeleton(counts: counts, days: [("2022-08-18", Self.august18), ("2022-08-17", Self.august17)])
    }

    private func makeSkeleton(counts: [Int], days: [(String, Date)]) -> PhotoLibrary {
        PhotoLibrary.skeleton(from: counts.enumerated().map { index, count in
            MediaDateSectionEntity(
                groupId: days[index].0, startDate: days[index].1, endDate: days[index].1, count: count)
        })
    }

    private func makeNode(
        handle: HandleEntity = 99,
        hasThumbnail: Bool = false,
        hasPreview: Bool = false,
        isFavourite: Bool = false,
        isMarkedSensitive: Bool = false
    ) -> NodeEntity {
        NodeEntity(
            handle: handle,
            hasThumbnail: hasThumbnail,
            hasPreview: hasPreview,
            isFavourite: isFavourite,
            isMarkedSensitive: isMarkedSensitive,
            // 2022-08-18T12:00:45Z — no time zone offset makes that a local midnight.
            modificationTime: Date(timeIntervalSince1970: 1_660_824_045))
    }

    // MARK: - Structure

    @Test
    func testChangedItemIndexPaths_itemCountChange_returnsNil() {
        let old = makeSkeleton(counts: [2, 1]).photoDaySections
        let new = makeSkeleton(counts: [1, 1]).photoDaySections
        // Item count differs → caller must fall back to a full reload.
        #expect(old.changedItemIndexPaths(to: new, amongPrepared: []) == nil)
    }

    @Test
    func testChangedItemIndexPaths_sectionCountChange_returnsNil() {
        let old = makeSkeleton(counts: [2, 1]).photoDaySections
        let new = makeSkeleton(counts: [2]).photoDaySections
        #expect(old.changedItemIndexPaths(to: new, amongPrepared: []) == nil)
    }

    /// The structure is still checked in full: a reload is decided before any cell is looked at, so
    /// it must not depend on which cells happen to be built.
    @Test
    func testChangedItemIndexPaths_structureChangeOutsidePreparedCells_returnsNil() {
        let old = makeSkeleton(counts: [2, 1]).photoDaySections
        let new = makeSkeleton(counts: [2, 2]).photoDaySections
        #expect(
            old.changedItemIndexPaths(
                to: new, amongPrepared: [IndexPath(item: 0, section: 0)]) == nil)
    }

    // MARK: - Prepared cells

    @Test
    func testChangedItemIndexPaths_identical_returnsEmpty() {
        let sections = makeSkeleton().photoDaySections
        let prepared: Set<IndexPath> = [IndexPath(item: 0, section: 0), IndexPath(item: 1, section: 0)]
        // No change → nothing to reconfigure (distinct from nil, which means "reload").
        #expect(sections.changedItemIndexPaths(to: sections, amongPrepared: prepared) == [])
    }

    @Test
    func testChangedItemIndexPaths_preparedPlaceholderHydrated_isDetected() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let old = skeleton.photoDaySections
        let new = skeleton.replacingPhotos(from: 1, with: [makeNode()]).photoDaySections
        let indexPath = IndexPath(item: 1, section: 0)

        #expect(old.changedItemIndexPaths(to: new, amongPrepared: [indexPath]) == [indexPath])
    }

    /// A cell that has not been built yet is left alone: there is nothing to reconfigure, and it is
    /// configured from the caller's updated data source when the collection view builds it.
    @Test
    func testChangedItemIndexPaths_hydrationOutsidePreparedCells_isIgnored() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let old = skeleton.photoDaySections
        let new = skeleton.replacingPhotos(from: 1, with: [makeNode()]).photoDaySections

        #expect(old.changedItemIndexPaths(to: new, amongPrepared: []) == [])
        #expect(
            old.changedItemIndexPaths(
                to: new, amongPrepared: [IndexPath(item: 0, section: 1)]) == [])
    }

    /// Every render-only field the comparison covers, flipped one at a time on the same node —
    /// handle and date unchanged, so only the metadata can be what is noticed.
    @Test
    func testChangedItemIndexPaths_metadataFlips_areDetected() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let old = skeleton.replacingPhotos(from: 1, with: [makeNode()]).photoDaySections
        let indexPath = IndexPath(item: 1, section: 0)
        let flips = [
            makeNode(hasThumbnail: true),
            makeNode(hasPreview: true),
            makeNode(isFavourite: true),
            makeNode(isMarkedSensitive: true)
        ]

        for flipped in flips {
            let new = skeleton.replacingPhotos(from: 1, with: [flipped]).photoDaySections
            #expect(old.changedItemIndexPaths(to: new, amongPrepared: [indexPath]) == [indexPath])
            // The same flip on a cell the collection view has not built.
            #expect(old.changedItemIndexPaths(to: new, amongPrepared: []) == [])
        }
    }

    @Test
    func testChangedItemIndexPaths_severalPreparedCells_returnsOnlyChangedOnes() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let old = skeleton.replacingPhotos(at: [0: makeNode(handle: 1), 1: makeNode(handle: 2)])
            .photoDaySections
        let new = skeleton.replacingPhotos(
            at: [0: makeNode(handle: 1), 1: makeNode(handle: 2, hasThumbnail: true)]).photoDaySections
        let prepared: Set<IndexPath> = [
            IndexPath(item: 0, section: 0), IndexPath(item: 1, section: 0), IndexPath(item: 0, section: 1)
        ]

        #expect(
            old.changedItemIndexPaths(to: new, amongPrepared: prepared)
            == [IndexPath(item: 1, section: 0)])
    }

    /// The old node-derived key could not tell two cells apart while a splice had one node in two
    /// slots. Index paths are unique by construction, so both cells compare independently.
    @Test
    func testChangedItemIndexPaths_sameNodeInTwoSlots_comparesEachCellIndependently() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let duplicated = makeNode()
        let old = skeleton.replacingPhotos(at: [0: duplicated, 1: duplicated]).photoDaySections
        let new = skeleton.replacingPhotos(
            at: [0: duplicated, 1: makeNode(hasThumbnail: true)]).photoDaySections

        #expect(
            old.changedItemIndexPaths(
                to: new,
                amongPrepared: [IndexPath(item: 0, section: 0), IndexPath(item: 1, section: 0)])
            == [IndexPath(item: 1, section: 0)])
    }

    /// A month section holds several day buckets, so an item is located by bisecting them rather
    /// than by indexing one list.
    @Test
    func testChangedItemIndexPaths_monthSectionSpanningDayBuckets_locatesItemAcrossBuckets() {
        let skeleton = makeSameMonthSkeleton(counts: [2, 2])
        let old = skeleton.photoMonthSections
        // Flat index 2 is the first slot of the second day bucket.
        let new = skeleton.replacingPhotos(from: 2, with: [makeNode()]).photoMonthSections

        #expect(old.count == 1)
        #expect(
            old.changedItemIndexPaths(to: new, amongPrepared: [IndexPath(item: 2, section: 0)])
            == [IndexPath(item: 2, section: 0)])
        #expect(
            old.changedItemIndexPaths(to: new, amongPrepared: [IndexPath(item: 1, section: 0)]) == [])
    }

    @Test
    func testChangedItemIndexPaths_returnsAscendingIndexPaths() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let old = skeleton.photoDaySections
        let new = skeleton.replacingPhotos(
            at: [1: makeNode(handle: 1), 2: makeNode(handle: 2)]).photoDaySections
        let prepared: Set<IndexPath> = [IndexPath(item: 0, section: 1), IndexPath(item: 1, section: 0)]

        #expect(
            old.changedItemIndexPaths(to: new, amongPrepared: prepared)
            == [IndexPath(item: 1, section: 0), IndexPath(item: 0, section: 1)])
    }

    /// An index path the sections no longer describe cannot be compared — and cannot be
    /// reconfigured either, so it is dropped rather than forcing a reload.
    @Test
    func testChangedItemIndexPaths_preparedIndexPathOutOfRange_isIgnored() {
        let sections = makeSkeleton(counts: [2, 1]).photoDaySections
        let prepared: Set<IndexPath> = [IndexPath(item: 7, section: 0), IndexPath(item: 0, section: 9)]

        #expect(sections.changedItemIndexPaths(to: sections, amongPrepared: prepared) == [])
    }

    /// Pins the API's shape: the work is bounded by the cells the collection view has built, not by
    /// the library. A hydration far outside that set contributes nothing.
    @Test
    func testChangedItemIndexPaths_largeLibrary_returnsOnlyPreparedChanges() {
        let skeleton = makeSkeleton(counts: [5_000, 5_000])
        let old = skeleton.photoDaySections
        let new = skeleton.replacingPhotos(
            at: [3: makeNode(handle: 3), 4_200: makeNode(handle: 4_200)]).photoDaySections
        let prepared: Set<IndexPath> = [
            IndexPath(item: 2, section: 0), IndexPath(item: 3, section: 0), IndexPath(item: 4, section: 0)
        ]

        #expect(
            old.changedItemIndexPaths(to: new, amongPrepared: prepared)
            == [IndexPath(item: 3, section: 0)])
    }
}
