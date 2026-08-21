@testable import ContentLibraries
import MEGADomain
import XCTest

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
    
    func testPositionAtIndexPath_monthSection() throws {
        let (dateSections, _) =  try makeSut(path: \.photoMonthSections)
        let position = dateSections.position(at: IndexPath(item: 0, section: 4))
        XCTAssertEqual(position, PhotoScrollPosition(handle: 7, date: try "2018-01-23T01:01:04Z".date))
    }
    
    func testPositionAtIndexPath_daySection() throws {
        let (dateSections, _) =  try makeSut(path: \.photoDaySections)
        let position = dateSections.position(at: IndexPath(item: 0, section: 2))
        XCTAssertEqual(position, PhotoScrollPosition(handle: 2, date: try "2022-08-10T22:01:04Z".date))
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
