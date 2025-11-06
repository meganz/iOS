@testable import ContentLibraries
import MEGADomain
import XCTest

final class PhotoChronologicalCategory_photoMonthSection_refreshTests: XCTestCase {
    
    func testShouldRefresh_photoMonthSectionAndEmpty_noRefresh() throws {
        let testCategories = [PhotoMonthSection]()
        let newCategories = [PhotoMonthSection]()
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_photoMonthSectionAndDifferentCount_refresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_photoMonthSectionAndNotEqualHandle_refresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date),
            NodeEntity(name: "i.jpg", handle: 9, modificationTime: try "2018-09-18T22:01:04Z".date),
            NodeEntity(name: "j.jpg", handle: 10, modificationTime: try "2016-03-18T22:01:04Z".date),
            NodeEntity(name: "k.jpg", handle: 11, modificationTime: try "2016-03-18T20:01:04Z".date),
            NodeEntity(name: "l.jpg", handle: 12, modificationTime: try "2016-03-15T10:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date),
            NodeEntity(name: "i.jpg", handle: 9, modificationTime: try "2018-09-18T22:01:04Z".date),
            NodeEntity(name: "j.jpg", handle: 10, modificationTime: try "2016-03-18T22:01:04Z".date),
            NodeEntity(name: "k.jpg", handle: 11, modificationTime: try "2016-03-18T20:01:04Z".date),
            NodeEntity(name: "l.jpg", handle: 120000, modificationTime: try "2016-03-15T10:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_photoMonthSectionAndNotEqualDate_refresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-05-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_photoMonthSectionAndEqual_noRefresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, isFavourite: true, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, hasPreview: true, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_photoMonthSectionAndRefreshable() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-07-18T20:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, hasPreview: true, modificationTime: try "2022-07-18T20:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
        
        let visibleAndRefreshableNodes = [
            NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, hasPreview: true, modificationTime: try "2022-07-18T20:01:04Z".date)
        ]
        
        for node in visibleAndRefreshableNodes {
            XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
        
        let visibleAndNonRefreshNodes = [
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
        
        for node in visibleAndNonRefreshNodes {
            XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
    }
    
    func testShouldRefresh_photoMonthSectionAndNonRefreshable_noRefresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, isShare: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, isFolder: true, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, isRemoved: true, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
        
        let visibleNodes = [
            NodeEntity(name: "a.jpg", handle: 1, isShare: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, isFolder: true, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, isRemoved: true, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
        
        for node in visibleNodes {
            XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
    }
    
    func testShouldRefresh_photoMonthSectionAndMultiplePhotosInOneMonth() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-08-17T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-08-16T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2022-08-15T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2022-08-14T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2022-08-13T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-17T22:01:04Z".date),
            NodeEntity(name: "i.jpg", handle: 9, modificationTime: try "2020-10-16T22:01:04Z".date),
            NodeEntity(name: "j.jpg", handle: 10, modificationTime: try "2020-10-12T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-08-17T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, hasThumbnail: true, modificationTime: try "2022-08-16T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, hasPreview: true, modificationTime: try "2022-08-15T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2022-08-14T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2022-08-13T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, hasThumbnail: true, modificationTime: try "2020-10-17T22:01:04Z".date),
            NodeEntity(name: "i.jpg", handle: 9, modificationTime: try "2020-10-16T22:01:04Z".date),
            NodeEntity(name: "j.jpg", handle: 10, hasPreview: true, modificationTime: try "2020-10-12T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
        
        let visibleAndRefreshableNodes = [
            NodeEntity(name: "c.mov", handle: 3, hasThumbnail: true, modificationTime: try "2022-08-16T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, hasPreview: true, modificationTime: try "2022-08-15T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, hasThumbnail: true, modificationTime: try "2020-10-17T22:01:04Z".date),
            NodeEntity(name: "j.jpg", handle: 10, hasPreview: true, modificationTime: try "2020-10-12T22:01:04Z".date)
        ]
        
        for node in visibleAndRefreshableNodes {
            XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
    }
    
    func testShouldRefresh_photoMonthSectionAndNodeChangeIsFavourite_refresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, isFavourite: true, modificationTime: try "2022-07-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date)
        ]
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
            .photoMonthSections
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))

        let visibleAndRefreshableNodes = [
            NodeEntity(name: "a.jpg", handle: 1, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date)
        ]
        
        for node in visibleAndRefreshableNodes {
            XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
    }
}
