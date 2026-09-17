@testable import ContentLibraries
import Foundation
import MEGADomain
import MEGAFoundation
import XCTest

private extension Date {
    /// The GMT day the date falls in — the `categoryDate` of the bucket holding it.
    var gmtDay: Date {
        get throws { try XCTUnwrap(removeTimestamp(timeZone: .GMT)) }
    }
}

final class PhotoDateSectionTests: XCTestCase {

    override func setUpWithError() throws {
        ContentLibraries.configuration = .mockConfiguration()
        try super.setUpWithError()
    }

    func testAllPhotos_monthSection_equal() throws {
        let (dateSections, testNodes) =  try makeSut(path: \.photoMonthSections)
        
        XCTAssertEqual(dateSections.allPhotos, testNodes)
    }
    
    func testAllPhotos_daySection_equal() throws {
        let (dateSections, testNodes) =  try makeSut(path: \.photoDaySections)
        XCTAssertEqual(dateSections.allPhotos, testNodes)
    }
    
    /// A paginated timeline's skeleton must not leak its synthetic slots to consumers that
    /// resolve nodes by handle, and the surviving real nodes must keep their grid order.
    func testHydratedPhotos_dropsSkeletonSlotsAndKeepsOrder() throws {
        let real = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.mp4", handle: 2, modificationTime: try "2022-08-18T21:01:04Z".date)
        ]
        let sections = [MediaDateSectionEntity(
            groupId: "2022-08-18",
            startDate: try "2022-08-18T00:00:00Z".date,
            endDate: try "2022-08-18T23:59:59Z".date,
            count: 4)]
        // Slots 0 and 2 stay placeholders, 1 and 3 are hydrated.
        let library = PhotoLibrary.skeleton(from: sections).replacingPhotos(at: [1: real[0], 3: real[1]])

        let dateSections = library.photoDaySections

        XCTAssertEqual(dateSections.allPhotos.count, 4)
        XCTAssertEqual(dateSections.hydratedPhotos, real)
    }

    func testHydratedPhotos_realLibraryIsUnchanged() throws {
        let (dateSections, testNodes) = try makeSut(path: \.photoDaySections)

        XCTAssertEqual(dateSections.hydratedPhotos, testNodes)
    }

    func testPhotoAtIndexPath_monthSection() throws {
        let (dateSections, _) =  try makeSut(path: \.photoMonthSections)
        XCTAssertEqual(dateSections.count, 6)
        
        let photo = dateSections.photo(at: IndexPath(item: 0, section: 5))
        XCTAssertEqual(photo, NodeEntity(handle: 8))
    }
    
    func testPhotoAtIndexPath_daySection() throws {
        let (dateSections, _) =  try makeSut(path: \.photoDaySections)
        XCTAssertEqual(dateSections.count, 7)
        
        let photo = dateSections.photo(at: IndexPath(item: 2, section: 3))
        XCTAssertEqual(photo, NodeEntity(handle: 5))
    }
    
    /// The position is dated by the day bucket the item sits in, not by the node's own
    /// timestamp — that is the date ``indexPath(of:in:)`` matches on.
    func testPositionAtIndexPath_monthSection() throws {
        let (dateSections, _) =  try makeSut(path: \.photoMonthSections)
        let position = dateSections.position(at: IndexPath(item: 0, section: 4))
        XCTAssertEqual(position, PhotoScrollPosition(handle: 7, date: try "2018-01-23T01:01:04Z".date.gmtDay))
    }
    
    func testPositionAtIndexPath_daySection() throws {
        let (dateSections, _) =  try makeSut(path: \.photoDaySections)
        let position = dateSections.position(at: IndexPath(item: 0, section: 2))
        XCTAssertEqual(position, PhotoScrollPosition(handle: 2, date: try "2022-08-10T22:01:04Z".date.gmtDay))
    }

    /// A month section holds several days; the item's position must carry its own day, not the
    /// section's first one.
    func testPositionAtIndexPath_monthSectionSecondDay_usesThatDaysDate() throws {
        let (dateSections, _) =  try makeSut(path: \.photoMonthSections)
        // Section 1 is August 2022: day 2022-08-18 followed by day 2022-08-10, so item 1 is
        // the first item of the second day.
        let position = dateSections.position(at: IndexPath(item: 1, section: 1))
        XCTAssertEqual(position, PhotoScrollPosition(handle: 2, date: try "2022-08-10T22:01:04Z".date.gmtDay))
    }

    /// On the paginated timeline the buckets come from the SDK's `groupId`s, so a hydrated
    /// node's modification time can sit in a completely different day — the position must
    /// still round-trip back to the item it was taken from.
    func testPositionAtIndexPath_hydratedNodeDatedOutsideItsBucket_usesTheBucketDate() throws {
        let dayDate = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2022, month: 8, day: 18)))
        let sections = [MediaDateSectionEntity(
            groupId: "2022-08-18", startDate: dayDate, endDate: dayDate, count: 2)]
        let hydrated = NodeEntity(
            name: "a.jpg", handle: 7, modificationTime: try "2019-03-04T10:00:00Z".date)
        let library = PhotoLibrary.skeleton(from: sections).replacingPhotos(at: [1: hydrated])
        let dateSections = library.photoDaySections

        let position = try XCTUnwrap(dateSections.position(at: IndexPath(item: 1, section: 0)))

        XCTAssertEqual(position, PhotoScrollPosition(handle: 7, date: dayDate))
        XCTAssertEqual(dateSections.indexPath(of: position), IndexPath(item: 1, section: 0))
    }
    
    // MARK: - Item access without flattening

    func testItemCount_matchesTheFlattenedItems() throws {
        let (monthSections, _) = try makeSut(path: \.photoMonthSections)
        let (daySections, _) = try makeSut(path: \.photoDaySections)

        XCTAssertEqual(monthSections.map(\.itemCount), monthSections.map { $0.contentList.count })
        XCTAssertEqual(daySections.map(\.itemCount), daySections.map { $0.contentList.count })
    }

    /// The items of a section are its days concatenated, so a month section has to resolve an
    /// index into the right day — the second day of August 2022 starts at item 1.
    func testNodeAt_monthSectionSpanningDays_resolvesEveryItem() throws {
        let (monthSections, _) = try makeSut(path: \.photoMonthSections)
        let august = monthSections[1]

        XCTAssertEqual(august.itemCount, 2)
        XCTAssertEqual(august.node(at: 0), NodeEntity(handle: 1))
        XCTAssertEqual(august.node(at: 1), NodeEntity(handle: 2))
    }

    func testNodeAt_outOfBounds_returnsNil() throws {
        let (monthSections, _) = try makeSut(path: \.photoMonthSections)
        let august = monthSections[1]

        XCTAssertNil(august.node(at: -1))
        XCTAssertNil(august.node(at: august.itemCount))
    }

    func testCoverPhoto_isTheFirstItemOfTheFirstDay() throws {
        let (monthSections, testNodes) = try makeSut(path: \.photoMonthSections)

        XCTAssertEqual(monthSections[1].coverPhoto, testNodes[1])
    }

    /// `PhotoByDay` does not forbid an empty bucket, and a section that opens with one still has
    /// a cover: the first item further down, dated by the day actually holding it.
    func testCover_leadingEmptyDay_takesTheFirstItemOfTheNextDay() throws {
        let emptyDay = try "2022-08-18T00:00:00Z".date
        let filledDay = try "2022-08-10T00:00:00Z".date
        let node = NodeEntity(name: "a.jpg", handle: 1, modificationTime: filledDay)
        let section = PhotoDateSection(
            photoByDayList: [
                PhotoByDay(categoryDate: emptyDay, contentList: []),
                PhotoByDay(categoryDate: filledDay, contentList: [node])
            ],
            categoryDate: emptyDay)

        XCTAssertEqual(section.coverPhoto, node)
        XCTAssertEqual(section.coverDayDate, filledDay)
        XCTAssertEqual(section.node(at: 0), node)
    }

    func testCover_sectionWithNoItems_isNil() throws {
        let day = try "2022-08-18T00:00:00Z".date
        let section = PhotoDateSection(
            photoByDayList: [PhotoByDay(categoryDate: day, contentList: [])], categoryDate: day)

        XCTAssertEqual(section.itemCount, 0)
        XCTAssertNil(section.coverPhoto)
        XCTAssertNil(section.coverDayDate)
    }

    /// The masonry section holds the whole library in one section, so building it must not copy
    /// the day buckets — it keeps the library's own arrays.
    func testMasonrySection_spansTheLibraryAndKeepsItsDayBuckets() throws {
        let (_, testNodes) = try makeSut(path: \.photoDaySections)
        let library = testNodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)

        let section = library.photoMasonrySection

        XCTAssertEqual(section.itemCount, testNodes.count)
        XCTAssertEqual((0..<section.itemCount).compactMap { section.node(at: $0) }, testNodes)
        for (source, held) in zip(library.photosByDayList, section.photoByDayList) {
            XCTAssertTrue(sharesStorage(source, held))
        }
    }

    /// True when the two buckets hand out one storage buffer, i.e. the section took the library's
    /// array rather than a copy of it. An equality check cannot tell the two apart.
    private func sharesStorage(_ lhs: PhotoByDay, _ rhs: PhotoByDay) -> Bool {
        lhs.contentList.withUnsafeBufferPointer { left in
            rhs.contentList.withUnsafeBufferPointer { right in
                left.baseAddress == right.baseAddress
            }
        }
    }

    func testIndexPathOfPosition_monthSection_found() throws {
        let (dateSections, _) =  try makeSut(path: \.photoMonthSections)
        let position = PhotoScrollPosition(handle: 4, date: try "2020-04-18T12:01:04Z".date)
        XCTAssertEqual(dateSections.indexPath(of: position, in: .GMT), IndexPath(item: 1, section: 2))
    }
    
    func testIndexPathOfPosition_monthSection_notFound() throws {
        let (dateSections, _) =  try makeSut(path: \.photoMonthSections)
        let position = PhotoScrollPosition(handle: 140, date: try "2020-04-18T12:01:04Z".date)
        XCTAssertNil(dateSections.indexPath(of: position, in: .GMT))
    }
    
    func testIndexPathOfPosition_monthSectionAndEmpty_notFound() throws {
        let dateSections = [PhotoDateSection]()
        let position = PhotoScrollPosition(handle: 4, date: try "2020-04-18T12:01:04Z".date)
        XCTAssertNil(dateSections.indexPath(of: position, in: .GMT))
    }
    
    func testIndexPathOfPosition_daySection_found() throws {
        let (dateSections, _) =  try makeSut(path: \.photoDaySections)
        let position = PhotoScrollPosition(handle: 4, date: try "2020-04-18T12:01:04Z".date)
        XCTAssertEqual(dateSections.indexPath(of: position, in: .GMT), IndexPath(item: 1, section: 3))
    }
    
    func testIndexPathOfPosition_daySection_notFound() throws {
        let (dateSections, _) =  try makeSut(path: \.photoDaySections)
        let position = PhotoScrollPosition(handle: 500, date: try "2020-04-18T12:01:04Z".date)
        XCTAssertNil(dateSections.indexPath(of: position, in: .GMT))
    }
    
    func testIndexPathOfPosition_daySectionAndEmpty_notFound() throws {
        let dateSections = [PhotoDateSection]()
        let position = PhotoScrollPosition(handle: 4, date: try "2020-04-18T12:01:04Z".date)
        XCTAssertNil(dateSections.indexPath(of: position, in: .GMT))
    }
}

extension PhotoDateSectionTests {
    
    func makeSut(
        path: KeyPath<PhotoLibrary, [some PhotoDateSection]>) throws -> (dateSections: [PhotoDateSection], testNodes: [NodeEntity]) {
            
        let testNodes = [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date),
            NodeEntity(name: "e.mp4", handle: 6, modificationTime: try "2019-10-18T01:01:04Z".date),
            NodeEntity(name: "f.mp4", handle: 7, modificationTime: try "2018-01-23T01:01:04Z".date),
            NodeEntity(name: "g.mp4", handle: 8, modificationTime: try "2017-12-31T01:01:04Z".date)
        ]
        
        let library = testNodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        
        return (dateSections: library[keyPath: path], testNodes: testNodes)
    }
}
