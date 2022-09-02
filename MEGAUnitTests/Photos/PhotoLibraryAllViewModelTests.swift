import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock
import SwiftUI
import MEGASwift

final class PhotoLibraryAllViewModelTests: XCTestCase {
    private var sut: PhotoLibraryAllViewModel!

    override func setUpWithError() throws {
        let nodes =  [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date),
        ]
        let library = nodes.toPhotoLibrary(withSortType: .newest, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .all
        sut = PhotoLibraryAllViewModel(libraryViewModel: libraryViewModel)
    }
    
    func testInit_defaultValue() throws {
        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2020-04-18T20:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: 3))
        XCTAssertNil(sut.selectedNode)
        XCTAssertEqual(sut.columns.count, 3)
        for column in sut.columns {
            guard case let GridItem.Size.flexible(minimum, maximum) = column.size else {
                XCTFail("column size should be flexible")
                return
            }
            
            XCTAssertEqual(minimum, 10)
            XCTAssertEqual(maximum, .infinity)
            XCTAssertEqual(column.spacing, 4)
        }
        XCTAssertEqual(sut.position, PhotoScrollPosition(handle: 0, date: try "2022-09-01T22:01:04Z".date))
    }
    
    func testZoomState_zoomInOneTime_daySection() throws {
        sut.zoomState.zoom(.in)
        
        XCTAssertEqual(sut.photoCategoryList.count, 4)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeTimestamp(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeTimestamp(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2022-08-10T22:01:04Z".date.removeTimestamp(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[3].categoryDate, try "2020-04-18T20:01:04Z".date.removeTimestamp(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[3].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: 1))
        XCTAssertNil(sut.selectedNode)
        XCTAssertEqual(sut.columns.count, 1)
        for column in sut.columns {
            guard case let GridItem.Size.flexible(minimum, maximum) = column.size else {
                XCTFail("column size should be flexible")
                return
            }
            
            XCTAssertEqual(minimum, 10)
            XCTAssertEqual(maximum, .infinity)
            XCTAssertEqual(column.spacing, 4)
        }
        XCTAssertEqual(sut.position, PhotoScrollPosition(handle: 0, date: try "2022-09-01T22:01:04Z".date))
    }

    
    func testZoomState_zoomInTwoTimes_daySection() throws {
        sut.zoomState.zoom(.in)
        try testZoomState_zoomInOneTime_daySection()
    }
    
    func testZoomState_zoomOutOneTime_monthSection() throws {
        sut.zoomState.zoom(.out)
        
        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2020-04-18T20:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: 5))
        XCTAssertNil(sut.selectedNode)
        XCTAssertEqual(sut.columns.count, 5)
        for column in sut.columns {
            guard case let GridItem.Size.flexible(minimum, maximum) = column.size else {
                XCTFail("column size should be flexible")
                return
            }
            
            XCTAssertEqual(minimum, 10)
            XCTAssertEqual(maximum, .infinity)
            XCTAssertEqual(column.spacing, 4)
        }
        XCTAssertEqual(sut.position, PhotoScrollPosition(handle: 0, date: try "2022-09-01T22:01:04Z".date))
    }
    
    func testZoomState_zoomOutTwoTimes_monthSection() throws {
        sut.zoomState.zoom(.out)
        try testZoomState_zoomOutOneTime_monthSection()
    }
}
