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
