@testable import ContentLibraries
import MEGADomain
import XCTest

final class PhotoChronologicalCategory_nodeEntity_refreshTests: XCTestCase {
    
    func testShouldRefresh_nodeEntityAndEmpty_noRefresh() throws {
        let testCategories = [NodeEntity]()
        let newCategories = [NodeEntity]()
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_nodeEntityAndDifferentCount_refresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date)
        ]
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date)
        ]
        
        XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_nodeEntityAndNotEqualHandle_refresh() throws {
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
        
        XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_nodeEntityAndNotEqualDate_refresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-05-18T22:01:04Z".date)
        ]
        
        XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_nodeEntityAndEqual_noRefresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, isFavourite: true, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, hasPreview: true, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
    }
    
    func testShouldRefresh_nodeEntityAndRefreshable() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, isFavourite: true, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, hasPreview: true, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
        
        let visibleAndRefreshableNodes = [
            NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, hasPreview: true, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
        
        for node in visibleAndRefreshableNodes {
            XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
        
        let visibleAndNonRefreshNodes = [
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
    
    func testShouldRefresh_nodeEntityAndNonRefreshable_noRefresh() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, isShare: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, isFolder: true, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, isRemoved: true, modificationTime: try "2022-04-18T22:01:04Z".date)
        ]
        
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
    
    func testShouldRefresh_sensitivityOfNodeChange_shouldRefreshVisible() throws {
        let testCategories = [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
        
        let newCategories = [
            NodeEntity(name: "a.jpg", handle: 1, isMarkedSensitive: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, isMarkedSensitive: true, modificationTime: try "2021-08-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
        
        XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [:]))
        
        let visibleAndRefreshableNodes = [
            NodeEntity(name: "a.jpg", handle: 1, isMarkedSensitive: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 4, isMarkedSensitive: true, modificationTime: try "2021-08-18T22:01:04Z".date)
        ]
        
        for node in visibleAndRefreshableNodes {
            XCTAssertTrue(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
        
        let visibleAndNonRefreshNodes = [
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2022-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2022-04-18T22:01:04Z".date),
            NodeEntity(name: "e.jpg", handle: 5, modificationTime: try "2021-01-18T22:01:04Z".date),
            NodeEntity(name: "f.jpg", handle: 6, modificationTime: try "2020-12-18T22:01:04Z".date),
            NodeEntity(name: "g.jpg", handle: 7, modificationTime: try "2020-10-18T22:01:04Z".date),
            NodeEntity(name: "h.jpg", handle: 8, modificationTime: try "2020-10-15T22:01:04Z".date)
        ]
        
        for node in visibleAndNonRefreshNodes {
            XCTAssertFalse(testCategories.shouldRefresh(to: newCategories, visiblePositions: [node.position: true]))
        }
    }
}
