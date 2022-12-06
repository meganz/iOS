import XCTest
@testable import MEGA

final class PhotoCellVideoDurationViewModelTests: XCTestCase {
    func testShouldShowDuration_video() {
        var sut = PhotoCellVideoDurationViewModel(isVideo: true, duration: "")
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.scaleFactor = scaleFactor
            XCTAssertEqual(sut.shouldShowDuration, scaleFactor != .thirteen)
        }
    }

    func testShouldShowDuration_notVideo() {
        var sut = PhotoCellVideoDurationViewModel(isVideo: false, duration: "")
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.scaleFactor = scaleFactor
            XCTAssertFalse(sut.shouldShowDuration)
        }
    }

}
