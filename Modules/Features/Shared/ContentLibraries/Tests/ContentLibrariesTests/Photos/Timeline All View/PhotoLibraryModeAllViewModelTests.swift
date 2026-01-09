@preconcurrency import Combine
@testable import ContentLibraries
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import MEGASwift
import SwiftUI
import XCTest

final class PhotoLibraryModeAllViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        ContentLibraries.configuration = .mockConfiguration()
        try super.setUpWithError()
    }

    @MainActor
    private func makeSUT() throws -> PhotoLibraryModeAllViewModel {
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
        return PhotoLibraryModeAllViewModel(libraryViewModel: libraryViewModel)
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
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .three, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }

    @MainActor
    func testZoomState_zoomInOneTime_daySection() throws {
        let sut = try makeSUT()
        sut.zoomState.zoom(.in)

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

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .one, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }

    @MainActor
    func testZoomState_zoomInTwoTimes_daySection() throws {
        let sut = try makeSUT()
        sut.zoomState.zoom(.in)
        sut.zoomState.zoom(.in)

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

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .one, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
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

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .five, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }

    @MainActor
    func testZoomState_zoomOutTwoTimes_monthSection() throws {
        let sut = try makeSUT()
        sut.zoomState.zoom(.out)
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

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .five, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }
    
    @MainActor
    func testZoomState_onChangeToThirteenScaleFactor_shouldChangeSelectionIsHidden() {
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let viewModel = PhotoLibraryModeAllViewModel(libraryViewModel: libraryViewModel)
        XCTAssertFalse(libraryViewModel.selection.isHidden)
        viewModel.zoomState.scaleFactor = .thirteen
        XCTAssertTrue(libraryViewModel.selection.isHidden)
    }
    
    @MainActor
    func testInvalidateCameraUploadEnabledSetting_whenIsCameraUploadsEnabledHasChanged_shouldTriggerShowEnableCameraUploadToEqualFalse() async {
        
        // Arrange
        let mockPreferences = MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false])
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let sut = PhotoLibraryModeAllViewModel(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: mockPreferences)
        
        // Act
        mockPreferences.dict[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] = true
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
        let mockPreferences = MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false])
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
