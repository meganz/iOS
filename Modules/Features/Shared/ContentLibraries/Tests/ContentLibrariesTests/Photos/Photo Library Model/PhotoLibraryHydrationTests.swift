@testable import ContentLibraries
import Foundation
import MEGADomain
import Testing

@Suite("PhotoLibrary Hydration Tests")
struct PhotoLibraryHydrationTests {

    /// Skeleton with two day buckets, counts 2 and 3 (5 placeholder slots total).
    private func makeSkeleton() -> PhotoLibrary {
        let day1 = Date(timeIntervalSince1970: 1_660_780_800) // 2022-08-18T00:00:00Z
        let day2 = Date(timeIntervalSince1970: 1_658_102_400) // 2022-07-18T00:00:00Z
        return PhotoLibrary.skeleton(from: [
            MediaDateSectionEntity(groupId: "2022-08-18", startDate: day1, endDate: day1, count: 2),
            MediaDateSectionEntity(groupId: "2022-07-18", startDate: day2, endDate: day2, count: 3)
        ])
    }

    private func dayBucketCounts(_ library: PhotoLibrary) -> [Int] {
        library.photoByYearList
            .flatMap(\.contentList).flatMap(\.contentList).map(\.contentList.count)
    }

    /// True when the two categories hand out the same storage buffer, i.e. the second was carried
    /// over rather than rebuilt. An equality check cannot tell the two apart.
    private func sharesStorage<T: PhotoChronologicalCategory>(_ lhs: T, _ rhs: T) -> Bool {
        lhs.contentList.withUnsafeBufferPointer { left in
            rhs.contentList.withUnsafeBufferPointer { right in
                left.baseAddress == right.baseAddress
            }
        }
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

    @Test("Only the day bucket the replacement lands in is rebuilt")
    func testReplacingPhotosAt_carriesUntouchedDayBucketsOver() {
        let skeleton = makeSkeleton() // two day buckets, in two different months
        let hydrated = skeleton.replacingPhotos(at: [0: NodeEntity(handle: 10)])

        let before = skeleton.photosByDayList
        let after = hydrated.photosByDayList
        #expect(!sharesStorage(before[0], after[0])) // rebuilt — the replacement landed here
        #expect(sharesStorage(before[1], after[1]))
    }

    @Test("A month with no replacement in it is carried over whole, not just its days")
    func testReplacingPhotosAt_carriesUntouchedMonthsOver() {
        let skeleton = makeSkeleton()
        let hydrated = skeleton.replacingPhotos(at: [0: NodeEntity(handle: 10)])

        let before = skeleton.photosByMonthList
        let after = hydrated.photosByMonthList
        #expect(!sharesStorage(before[0], after[0]))
        #expect(sharesStorage(before[1], after[1]))
    }

    @Test
    func testReplacingPhotosAt_ignoresOutOfRangeIndices() {
        let skeleton = makeSkeleton()
        let hydrated = skeleton.replacingPhotos(at: [99: NodeEntity(handle: 10)])
        #expect(hydrated == skeleton)
        // Nothing landed anywhere, so no bucket was rebuilt.
        #expect(zip(skeleton.photosByDayList, hydrated.photosByDayList).allSatisfy { sharesStorage($0, $1) })
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
}
