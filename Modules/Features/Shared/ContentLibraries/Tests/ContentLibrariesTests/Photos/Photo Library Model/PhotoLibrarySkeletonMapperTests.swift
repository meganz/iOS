@testable import ContentLibraries
import Foundation
import MEGADomain
import XCTest

final class PhotoLibrarySkeletonMapperTests: XCTestCase {

    // MARK: - Local-calendar date builders

    // Match the mapper: Gregorian groupId in the user's time zone.
    private let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()
    private func day(_ groupId: String) -> Date {
        let parts = groupId.split(separator: "-").compactMap { Int($0) }
        return gregorian.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))!
    }
    private func monthStart(_ year: Int, _ month: Int) -> Date {
        gregorian.date(from: DateComponents(year: year, month: month, day: 1))!
    }
    private func yearStart(_ year: Int) -> Date {
        gregorian.date(from: DateComponents(year: year, month: 1, day: 1))!
    }

    /// Day-granularity sections in newest-first display order. "2022-08-01" is deliberately a
    /// first-of-month day, to prove month/year aggregation groups by the `groupId` and keeps it
    /// in August. The zero-count section must be dropped.
    private func makeSections() -> [MediaDateSectionEntity] {
        [
            ("2022-08-18", 2),
            ("2022-08-01", 1),
            ("2022-07-18", 3),
            ("2021-01-05", 1),
            ("2020-06-01", 0)
        ].map { groupId, count in
            MediaDateSectionEntity(groupId: groupId, startDate: day(groupId), endDate: day(groupId), count: count)
        }
    }

    func testSkeleton_totalCountMatchesSumOfCounts() {
        let library = PhotoLibrary.skeleton(from: makeSections())
        XCTAssertEqual(library.allPhotos.count, 7) // 2 + 1 + 3 + 1, zero-count dropped
    }

    /// Boundary dates must preserve every placeholder slot.
    func testSkeleton_totalCountPreservedForBoundaryDates() {
        let sections = [
            ("2100-01-01", 3), // far future, first-of-month
            ("2024-02-29", 2), // leap day
            ("2022-12-31", 5),
            ("1970-01-01", 4)  // epoch
        ].map { groupId, count in
            MediaDateSectionEntity(groupId: groupId, startDate: day(groupId), endDate: day(groupId), count: count)
        }

        let library = PhotoLibrary.skeleton(from: sections)

        XCTAssertEqual(library.allPhotos.count, 14) // 3 + 2 + 5 + 4, nothing dropped
        let dayCount = library.photoByYearList
            .flatMap(\.contentList).flatMap(\.contentList).count
        XCTAssertEqual(dayCount, 4) // one PhotoByDay per non-zero section
        XCTAssertTrue(library.allPhotos.allSatisfy(\.isTimelinePlaceholder))
    }

    func testSkeleton_buildsCorrectTreeShapeInInputOrder() {
        let library = PhotoLibrary.skeleton(from: makeSections())

        let years = library.photoByYearList
        XCTAssertEqual(years.count, 2)
        XCTAssertEqual(years.map(\.categoryDate), [yearStart(2022), yearStart(2021)])

        // 2022: August then July (input order preserved).
        let months2022 = years[0].contentList
        XCTAssertEqual(months2022.map(\.categoryDate), [monthStart(2022, 8), monthStart(2022, 7)])

        // August has two days (18th, 1st); the boundary 08-01 stayed in August via its groupId.
        let augustDays = months2022[0].contentList
        XCTAssertEqual(augustDays.map(\.categoryDate), [day("2022-08-18"), day("2022-08-01")])
        XCTAssertEqual(augustDays.map(\.contentList.count), [2, 1])

        // 2021 has a single month/day of one slot.
        XCTAssertEqual(years[1].contentList.count, 1)
        XCTAssertEqual(years[1].contentList[0].contentList.count, 1)
    }

    func testSkeleton_dayCategoryDatesComeFromGroupId() {
        let library = PhotoLibrary.skeleton(from: makeSections())
        let dayDates = library.photoByYearList
            .flatMap(\.contentList).flatMap(\.contentList).map(\.categoryDate)
        XCTAssertEqual(dayDates, [
            day("2022-08-18"),
            day("2022-08-01"),
            day("2022-07-18"),
            day("2021-01-05")
        ])
    }

    /// Headers must follow groupId, not a divergent startDate.
    func testSkeleton_headerDatesFollowGroupId_notDivergentStartDate() {
        let divergentStart = day("2022-11-30") // a startDate that disagrees with the groupId's month
        let sections = [MediaDateSectionEntity(
            groupId: "2022-12-01", startDate: divergentStart, endDate: divergentStart, count: 1)]

        let library = PhotoLibrary.skeleton(from: sections)
        let yearNode = library.photoByYearList[0]
        let monthNode = yearNode.contentList[0]
        let dayNode = monthNode.contentList[0]

        XCTAssertEqual(dayNode.categoryDate, day("2022-12-01"))
        XCTAssertEqual(monthNode.categoryDate, monthStart(2022, 12)) // December, not November
        XCTAssertEqual(yearNode.categoryDate, yearStart(2022))
        XCTAssertNotEqual(dayNode.categoryDate, divergentStart)
    }

    func testSkeleton_everySlotIsPlaceholderWithUniqueHandle() {
        let library = PhotoLibrary.skeleton(from: makeSections())
        let photos = library.allPhotos

        XCTAssertTrue(photos.allSatisfy(\.isTimelinePlaceholder))
        XCTAssertEqual(Set(photos.map(\.handle)).count, photos.count) // all handles unique
    }

    func testIsTimelinePlaceholder_trueOnlyForSyntheticSlots() {
        // A generated skeleton slot is a placeholder.
        XCTAssertTrue(NodeEntity.timelinePlaceholder(offset: 0, date: Date()).isTimelinePlaceholder)
        // A real, low-range handle is not.
        XCTAssertFalse(NodeEntity(handle: 42).isTimelinePlaceholder)
        // The all-ones invalid handle lands in the reserved band but must NOT be treated
        // as a placeholder, or invalid nodes would be silently skipped downstream.
        XCTAssertFalse(NodeEntity(handle: .invalid).isTimelinePlaceholder)
    }

    func testSkeleton_emptyInputProducesEmptyLibrary() {
        XCTAssertTrue(PhotoLibrary.skeleton(from: []).isEmpty)
    }

    func testSkeleton_allZeroCountsProducesEmptyLibrary() {
        let sections = [MediaDateSectionEntity(
            groupId: "2022-08-18", startDate: day("2022-08-18"), endDate: day("2022-08-18"), count: 0)]
        XCTAssertTrue(PhotoLibrary.skeleton(from: sections).isEmpty)
    }
}
