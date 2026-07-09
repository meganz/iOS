@testable import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAFoundation
import XCTest

final class PhotoLibrarySkeletonMapperTests: XCTestCase {

    /// Day-granularity sections in newest-first display order. "2022-08-01T00:00:00Z" is
    /// deliberately a first-of-month UTC midnight, to prove GMT aggregation keeps it in
    /// August (a negative-offset local calendar would roll it back into July). The
    /// zero-count section must be dropped.
    private func makeSections() throws -> [MediaDateSectionEntity] {
        try [
            ("2022-08-18T00:00:00Z", 2),
            ("2022-08-01T00:00:00Z", 1),
            ("2022-07-18T00:00:00Z", 3),
            ("2021-01-05T00:00:00Z", 1),
            ("2020-06-01T00:00:00Z", 0)
        ].map { iso, count in
            let start = try iso.date
            return MediaDateSectionEntity(groupId: iso, startDate: start, endDate: start, count: count)
        }
    }

    func testSkeleton_totalCountMatchesSumOfCounts() throws {
        let library = PhotoLibrary.skeleton(from: try makeSections())
        XCTAssertEqual(library.allPhotos.count, 7) // 2 + 1 + 3 + 1, zero-count dropped
    }

    /// The mapper must never silently drop a slot during month/year aggregation: the
    /// total placeholder count stays equal to the sum of section counts, and there is
    /// exactly one `PhotoByDay` per non-zero section — even for boundary dates (leap day,
    /// first-of-month UTC midnight, epoch, far future) that stress the calendar math
    /// behind `removeDay`/`removeMonth`.
    func testSkeleton_totalCountPreservedForBoundaryDates() throws {
        let sections = try [
            ("2100-01-01T00:00:00Z", 3), // far future, first-of-month UTC midnight
            ("2024-02-29T00:00:00Z", 2), // leap day
            ("2022-12-31T00:00:00Z", 5),
            ("1970-01-01T00:00:00Z", 4)  // epoch
        ].map { iso, count -> MediaDateSectionEntity in
            let start = try iso.date
            return MediaDateSectionEntity(groupId: iso, startDate: start, endDate: start, count: count)
        }

        let library = PhotoLibrary.skeleton(from: sections)

        XCTAssertEqual(library.allPhotos.count, 14) // 3 + 2 + 5 + 4, nothing dropped
        let dayCount = library.photoByYearList
            .flatMap(\.contentList).flatMap(\.contentList).count
        XCTAssertEqual(dayCount, 4) // one PhotoByDay per non-zero section
        XCTAssertTrue(library.allPhotos.allSatisfy(\.isTimelinePlaceholder))
    }

    func testSkeleton_buildsCorrectTreeShapeInInputOrder() throws {
        let library = PhotoLibrary.skeleton(from: try makeSections())

        let years = library.photoByYearList
        XCTAssertEqual(years.count, 2)
        XCTAssertEqual(years.map(\.categoryDate), [
            try "2022-01-01T00:00:00Z".date,
            try "2021-01-01T00:00:00Z".date
        ])

        // 2022: August then July (input order preserved).
        let months2022 = years[0].contentList
        XCTAssertEqual(months2022.map(\.categoryDate), [
            try "2022-08-01T00:00:00Z".date,
            try "2022-07-01T00:00:00Z".date
        ])

        // August has two days (18th, 1st); the boundary 08-01 stayed in August via GMT.
        let augustDays = months2022[0].contentList
        XCTAssertEqual(augustDays.map(\.categoryDate), [
            try "2022-08-18T00:00:00Z".date,
            try "2022-08-01T00:00:00Z".date
        ])
        XCTAssertEqual(augustDays.map(\.contentList.count), [2, 1])

        // 2021 has a single month/day of one slot.
        XCTAssertEqual(years[1].contentList.count, 1)
        XCTAssertEqual(years[1].contentList[0].contentList.count, 1)
    }

    func testSkeleton_dayCategoryDatesEqualSectionStarts() throws {
        let library = PhotoLibrary.skeleton(from: try makeSections())
        let dayDates = library.photoByYearList
            .flatMap(\.contentList).flatMap(\.contentList).map(\.categoryDate)
        XCTAssertEqual(dayDates, try [
            "2022-08-18T00:00:00Z".date,
            "2022-08-01T00:00:00Z".date,
            "2022-07-18T00:00:00Z".date,
            "2021-01-05T00:00:00Z".date
        ])
    }

    func testSkeleton_everySlotIsPlaceholderWithUniqueHandle() throws {
        let library = PhotoLibrary.skeleton(from: try makeSections())
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

    func testSkeleton_allZeroCountsProducesEmptyLibrary() throws {
        let start = try "2022-08-18T00:00:00Z".date
        let sections = [MediaDateSectionEntity(groupId: "x", startDate: start, endDate: start, count: 0)]
        XCTAssertTrue(PhotoLibrary.skeleton(from: sections).isEmpty)
    }
}
