@testable import ContentLibraries
import Foundation
import MEGADomain
import MEGAFoundation
import Testing

/// A scroll position is resolved by matching the day bucket it was taken in, so every category
/// level must date its position by the day its cover photo renders under — not by the cover
/// node's own timestamp, which on the paginated timeline routinely belongs to another day.
@Suite("PhotoChronologicalCategory position Tests")
struct PhotoChronologicalCategoryPositionTests {

    // MARK: - Eager path

    @Test
    func position_dayMonthAndYear_areDatedByTheCoverPhotosDayBucket() throws {
        let library = try makeLibrary()
        let coverDay = try "2022-08-18T22:01:04Z".date.gmtDay
        let expected = PhotoScrollPosition(handle: 1, date: coverDay)

        #expect(library.photosByDayList[0].position == expected)
        #expect(library.photosByMonthList[0].position == expected)
        #expect(library.photoByYearList[0].position == expected)
    }

    /// A month's position must carry its cover photo's day, not the first of the month — the
    /// lookup it feeds searches day buckets, and the 1st may hold no photos at all.
    @Test
    func position_month_isNotTheMonthStart() throws {
        let library = try makeLibrary()
        let month = library.photosByMonthList[0]

        #expect(month.position?.date == (try "2022-08-18T22:01:04Z".date.gmtDay))
        #expect(month.position?.date != month.categoryDate, "the month start is not a day bucket")
    }

    /// The leaf has no view of the tree, so it can only answer with its own date.
    @Test
    func position_node_fallsBackToItsOwnDate() throws {
        let node = NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date)

        #expect(node.position == PhotoScrollPosition(handle: 1, date: node.modificationTime))
    }

    // MARK: - Paginated path

    /// The bucketing case that motivates all of the above: ordered by media capture time, a
    /// hydrated node's modification time falls in a different day than the bucket holding it.
    @Test
    func position_hydratedNodeDatedOutsideItsBucket_usesTheBucketDate() throws {
        let dayDate = try #require(Calendar.current.date(from: DateComponents(year: 2022, month: 8, day: 18)))
        let sections = [MediaDateSectionEntity(
            groupId: "2022-08-18", startDate: dayDate, endDate: dayDate, count: 2)]
        let hydrated = NodeEntity(
            name: "a.jpg", handle: 7, modificationTime: try "2019-03-04T10:00:00Z".date)
        let library = PhotoLibrary.skeleton(from: sections).replacingPhotos(at: [0: hydrated])

        let expected = PhotoScrollPosition(handle: 7, date: dayDate)
        #expect(library.photosByDayList[0].position == expected)
        #expect(library.photosByMonthList[0].position == expected)
        #expect(library.photoByYearList[0].position == expected)
        #expect(library.photoDaySections[0].position == expected)
        #expect(library.photoMonthSections[0].position == expected)
    }

    /// Placeholder slots are dated by their own bucket, so an unhydrated skeleton resolves too.
    @Test
    func position_placeholderCover_usesTheBucketDate() throws {
        let dayDate = try #require(Calendar.current.date(from: DateComponents(year: 2022, month: 12, day: 1)))
        // A startDate that disagrees with the groupId, as the SDK's fixed UTC offset can produce.
        let divergentStart = try #require(Calendar.current.date(from: DateComponents(year: 2022, month: 11, day: 30)))
        let sections = [MediaDateSectionEntity(
            groupId: "2022-12-01", startDate: divergentStart, endDate: divergentStart, count: 1)]

        let library = PhotoLibrary.skeleton(from: sections)

        #expect(library.photosByDayList[0].position?.date == dayDate)
        #expect(library.photoByYearList[0].position?.date == dayDate)
    }

    // MARK: - Helpers

    /// Newest-first library whose top year / month / day are all covered by handle 1.
    private func makeLibrary() throws -> PhotoLibrary {
        [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date),
            NodeEntity(name: "c.jpg", handle: 3, modificationTime: try "2021-04-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
    }
}

private extension Date {
    /// The GMT day the date falls in — the `categoryDate` of the bucket holding it.
    var gmtDay: Date {
        get throws { try #require(removeTimestamp(timeZone: .GMT)) }
    }
}
