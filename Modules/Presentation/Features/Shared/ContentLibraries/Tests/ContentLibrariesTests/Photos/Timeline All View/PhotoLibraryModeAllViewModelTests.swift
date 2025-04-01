@preconcurrency import Combine
@testable import ContentLibraries
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import SwiftUI
import XCTest

final class PhotoLibraryModeAllViewModelTests: XCTestCase {
    @MainActor
    private func makeSUT() throws -> PhotoLibraryModeAllGridViewModel {
        let nodes =  [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .all
        return PhotoLibraryModeAllGridViewModel(libraryViewModel: libraryViewModel)
    }
    
    @MainActor
    func testInit_defaultValue() throws {
        let sut = try makeSUT()
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
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .three))
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
    
    @MainActor
    func testZoomState_zoomInOneTime_daySection() throws {
        let sut = try makeSUT()
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
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .one))
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

    @MainActor
    func testZoomState_zoomInTwoTimes_daySection() throws {
        let sut = try makeSUT()
        sut.zoomState.zoom(.in)
        try testZoomState_zoomInOneTime_daySection()
    }
    
    @MainActor
    func testZoomState_zoomOutOneTime_monthSection() throws {
        let sut = try makeSUT()
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
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .five))
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
    
    @MainActor
    func testZoomState_zoomOutTwoTimes_monthSection() throws {
        let sut = try makeSUT()
        sut.zoomState.zoom(.out)
        try testZoomState_zoomOutOneTime_monthSection()
    }
    
    @MainActor
    func testZoomState_onChangeToThirteenScaleFactor_shouldChangeSelectionIsHidden() {
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let viewModel = PhotoLibraryModeAllGridViewModel(libraryViewModel: libraryViewModel)
        XCTAssertFalse(libraryViewModel.selection.isHidden)
        viewModel.zoomState.scaleFactor = .thirteen
        XCTAssertTrue(libraryViewModel.selection.isHidden)
    }
    
    @MainActor
    func testInvalidateCameraUploadEnabledSetting_whenIsCameraUploadsEnabledHasChanged_shouldTriggerShowEnableCameraUploadToEqualFalse() async {
        
        // Arrange
        let mockPreferences = MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: false])
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let sut = PhotoLibraryModeAllViewModel(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: mockPreferences)
        
        // Act
        mockPreferences.dict[.isCameraUploadsEnabled] = true
        sut.invalidateCameraUploadEnabledSetting()
        
        let resultExpectation = expectation(description: "Expect showEnableCameraUpload to emit correct value")
        let subscription = sut.$showEnableCameraUpload
            .first { !$0 }
            .sink { result in
                XCTAssertFalse(result)
                resultExpectation.fulfill()
            }
        
        // Assert
        await fulfillment(of: [resultExpectation], timeout: 1)
        subscription.cancel()
    }
    
    @MainActor
    func testInvalidateCameraUploadEnabledSetting_whenIsCameraUploadsEnabledHasNotChanged_shouldTriggerShowEnableCameraUploadToEqualTrue() async {
        
        // Arrange
        let mockPreferences = MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: false])
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let sut = PhotoLibraryModeAllViewModel(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: mockPreferences)
        
        // Act
        sut.invalidateCameraUploadEnabledSetting()

        let results: Bool? = await sut.$showEnableCameraUpload
            .timeout(.seconds(1), scheduler: DispatchQueue.main)
            .last()
            .values
            .first(where: { @Sendable _ in true })
        
        // Assert
        XCTAssertEqual(results, true)
    }
}
