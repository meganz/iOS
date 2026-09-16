@testable import ContentLibraries
import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("PhotoSection changedItemIndexPaths Tests")
struct PhotoSection_changedItemIndexPathsTests {

    /// A skeleton with two day buckets → day sections sized from `counts`
    /// (default [2, 1] gives sections of 2 and 1 items; flat order [0, 1 | 2]).
    private func makeSkeleton(counts: [Int] = [2, 1]) -> PhotoLibrary {
        let days = [
            ("2022-08-18", Date(timeIntervalSince1970: 1_660_780_800)), // 2022-08-18T00:00:00Z
            ("2022-07-18", Date(timeIntervalSince1970: 1_658_102_400))  // 2022-07-18T00:00:00Z
        ]
        let sections = counts.enumerated().map { index, count in
            MediaDateSectionEntity(
                groupId: days[index].0, startDate: days[index].1, endDate: days[index].1, count: count)
        }
        return PhotoLibrary.skeleton(from: sections)
    }

    @Test
    func testChangedItemIndexPaths_identical_returnsEmpty() {
        let sections = makeSkeleton().photoDaySections
        // No change → nothing to reconfigure (distinct from nil, which means "reload").
        #expect(sections.changedItemIndexPaths(to: sections) == [])
    }

    @Test
    func testChangedItemIndexPaths_structuralChange_returnsNil() {
        let old = makeSkeleton(counts: [2, 1]).photoDaySections
        let new = makeSkeleton(counts: [1, 1]).photoDaySections
        // Item-count differs → caller must fall back to a full reload.
        #expect(old.changedItemIndexPaths(to: new) == nil)
    }

    /// A thumbnail arriving is only visible to the on-screen comparison, so it is seen when — and
    /// only when — the cell is named as visible.
    @Test
    func testChangedItemIndexPaths_visibleThumbnailFlip_isDetectedOnlyForVisibleCells() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let hydrated = NodeEntity(
            // 2022-08-18T12:00:45Z — no time zone offset makes that a local midnight.
            handle: 99, modificationTime: Date(timeIntervalSince1970: 1_660_824_045))
        let old = skeleton.replacingPhotos(from: 1, with: [hydrated]).photoDaySections
        let withThumbnail = NodeEntity(
            handle: 99, hasThumbnail: true, modificationTime: hydrated.modificationTime)
        let new = skeleton.replacingPhotos(from: 1, with: [withThumbnail]).photoDaySections
        let indexPath = IndexPath(item: 1, section: 0)

        #expect(old.changedItemIndexPaths(to: new) == [])
        #expect(old.changedItemIndexPaths(to: new, visibleIndexPaths: [indexPath]) == [indexPath])
        // A different cell being on screen says nothing about this one.
        #expect(old.changedItemIndexPaths(to: new, visibleIndexPaths: [IndexPath(item: 0, section: 1)]) == [])
    }

    /// The old node-derived key could not tell two cells apart while a splice had one node in two
    /// slots. Index paths are unique by construction, so both cells compare independently.
    @Test
    func testChangedItemIndexPaths_sameNodeInTwoSlots_comparesEachCellIndependently() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let duplicated = NodeEntity(handle: 99, modificationTime: Date(timeIntervalSince1970: 1_660_824_045))
        let old = skeleton.replacingPhotos(at: [0: duplicated, 1: duplicated]).photoDaySections
        let withThumbnail = NodeEntity(
            handle: 99, hasThumbnail: true, modificationTime: duplicated.modificationTime)
        let new = skeleton.replacingPhotos(at: [0: duplicated, 1: withThumbnail]).photoDaySections

        #expect(
            old.changedItemIndexPaths(
                to: new, visibleIndexPaths: [IndexPath(item: 0, section: 0), IndexPath(item: 1, section: 0)])
            == [IndexPath(item: 1, section: 0)])
    }

    @Test
    func testChangedItemIndexPaths_contentOnlyChange_returnsOnlyChangedCell() {
        let skeleton = makeSkeleton(counts: [2, 1])
        let old = skeleton.photoDaySections
        // Hydrate flat index 1 only (section 0, item 1); everything else stays a placeholder.
        let new = skeleton.replacingPhotos(from: 1, with: [NodeEntity(handle: 99)]).photoDaySections

        #expect(old.changedItemIndexPaths(to: new) == [IndexPath(item: 1, section: 0)])
    }
}
