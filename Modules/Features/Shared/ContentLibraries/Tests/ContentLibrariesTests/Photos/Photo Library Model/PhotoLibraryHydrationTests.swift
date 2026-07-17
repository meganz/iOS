@testable import ContentLibraries
import Foundation
import MEGADomain
import Testing

@Suite("PhotoLibrary Hydration Tests")
struct PhotoLibraryHydrationTests {

    /// Skeleton with two UTC day buckets, counts 2 and 3 (5 placeholder slots total).
    private func makeSkeleton() -> PhotoLibrary {
        let day1 = Date(timeIntervalSince1970: 1_660_780_800) // 2022-08-18T00:00:00Z
        let day2 = Date(timeIntervalSince1970: 1_658_102_400) // 2022-07-18T00:00:00Z
        return PhotoLibrary.skeleton(from: [
            MediaDateSectionEntity(groupId: "d1", startDate: day1, endDate: day1, count: 2),
            MediaDateSectionEntity(groupId: "d2", startDate: day2, endDate: day2, count: 3)
        ])
    }

    private func dayBucketCounts(_ library: PhotoLibrary) -> [Int] {
        library.photoByYearList
            .flatMap(\.contentList).flatMap(\.contentList).map(\.contentList.count)
    }

    @Test
    func testReplacingPhotos_swapsWindowInPlacePreservingStructure() {
        let skeleton = makeSkeleton()
        let reals = [NodeEntity(handle: 10), NodeEntity(handle: 11)]

        let hydrated = skeleton.replacingPhotos(from: 1, with: reals)

        let photos = hydrated.allPhotos
        #expect(photos.count == 5) // total count preserved
        #expect(photos[0].isTimelinePlaceholder)
        #expect(photos[1].handle == 10)
        #expect(photos[2].handle == 11)
        #expect(photos[3].isTimelinePlaceholder)
        #expect(photos[4].isTimelinePlaceholder)
        // Day buckets keep their sizes — nodes are spliced by position, not re-grouped by date.
        #expect(dayBucketCounts(hydrated) == [2, 3])
    }

    @Test
    func testReplacingPhotos_emptyReplacements_returnsUnchanged() {
        let skeleton = makeSkeleton()
        #expect(skeleton.replacingPhotos(from: 0, with: []) == skeleton)
    }

    @Test
    func testReplacingPhotosAt_swapsDisjointSlotsInOneTraversal() {
        let skeleton = makeSkeleton() // 5 placeholder slots (2 + 3)
        // Two disjoint runs at once: slot 1 and slots 3..4.
        let hydrated = skeleton.replacingPhotos(at: [
            1: NodeEntity(handle: 10),
            3: NodeEntity(handle: 30),
            4: NodeEntity(handle: 31)
        ])

        let photos = hydrated.allPhotos
        #expect(photos.count == 5)
        #expect(photos[0].isTimelinePlaceholder)
        #expect(photos[1].handle == 10)
        #expect(photos[2].isTimelinePlaceholder)
        #expect(photos[3].handle == 30)
        #expect(photos[4].handle == 31)
        #expect(dayBucketCounts(hydrated) == [2, 3]) // shape preserved
    }

    @Test
    func testReplacingPhotosAt_ignoresOutOfRangeIndices() {
        let skeleton = makeSkeleton()
        let hydrated = skeleton.replacingPhotos(at: [99: NodeEntity(handle: 10)])
        #expect(hydrated == skeleton)
    }

    @Test
    func testReplacingPhotos_windowLongerThanTree_ignoresOverflow() {
        let skeleton = makeSkeleton()
        let reals = (0..<10).map { NodeEntity(handle: HandleEntity(100 + $0)) }

        let hydrated = skeleton.replacingPhotos(from: 3, with: reals)

        let photos = hydrated.allPhotos
        #expect(photos.count == 5) // no growth
        #expect(photos[0].isTimelinePlaceholder)
        #expect(photos[2].isTimelinePlaceholder)
        #expect(photos[3].handle == 100)
        #expect(photos[4].handle == 101) // overflow (102...) dropped
    }

    @Test
    func testMergingMetadata_adoptsOtherNodeWhenPreferred_keepingPosition() {
        let base = makeSkeleton().replacingPhotos(from: 0, with: [
            NodeEntity(handle: 10, isFavourite: false),
            NodeEntity(handle: 11, isFavourite: false)
        ])
        let other = makeSkeleton().replacingPhotos(from: 0, with: [
            NodeEntity(handle: 10, isFavourite: true), // favourited concurrently
            NodeEntity(handle: 11, isFavourite: false)
        ])

        let merged = base.mergingMetadata(from: other) { mine, other in mine.isFavourite != other.isFavourite }

        #expect(merged.allPhotos[0].isFavourite) // adopted other's fresher node at the same slot
        #expect(!merged.allPhotos[1].isFavourite)
        #expect(dayBucketCounts(merged) == [2, 3]) // shape preserved
    }

    @Test
    func testMergingMetadata_neverOverridesNodeAbsentFromOther() {
        // A node freshly hydrated by this pass is still a placeholder in `other`, so it must survive.
        let base = makeSkeleton().replacingPhotos(from: 0, with: [NodeEntity(handle: 10, hasThumbnail: true)])
        let other = makeSkeleton() // all placeholders — no real node for handle 10

        let merged = base.mergingMetadata(from: other) { _, _ in true } // would adopt if matched

        #expect(merged.allPhotos[0].handle == 10)
        #expect(merged.allPhotos[0].hasThumbnail) // kept
    }

    @Test
    func testMergingMetadata_readinessSafePolicy_keepsTheMoreReadyNode() {
        // Mirrors the reactive path's policy: never let a staler `other` drop readiness `mine` has.
        let base = makeSkeleton().replacingPhotos(from: 0, with: [NodeEntity(handle: 10, hasThumbnail: true)])
        let other = makeSkeleton().replacingPhotos(from: 0, with: [NodeEntity(handle: 10, hasThumbnail: false)])

        let merged = base.mergingMetadata(from: other) { mine, other in
            guard mine.hasThumbnail != other.hasThumbnail else { return false }
            if mine.hasThumbnail && !other.hasThumbnail { return false }
            return true
        }

        #expect(merged.allPhotos[0].hasThumbnail) // the more-ready node wins; readiness never regresses
    }

    @Test
    func testMergingMetadata_noMatchingRealHandles_returnsUnchanged() {
        let base = makeSkeleton().replacingPhotos(from: 0, with: [NodeEntity(handle: 10)])
        #expect(base.mergingMetadata(from: makeSkeleton()) { _, _ in true } == base)
    }
}
