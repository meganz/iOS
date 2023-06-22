@testable import MEGA
import XCTest

final class PhotoCellVideoDurationViewModelTests: XCTestCase {
    func testShouldShowDurationView_video() {
        var sut = PhotoCellVideoDurationViewModel(isVideo: true, duration: "")
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.scaleFactor = scaleFactor
            XCTAssertEqual(sut.shouldShowDurationView, scaleFactor != .thirteen)
        }
    }

    func testShouldShowDurationView_notVideo() {
        var sut = PhotoCellVideoDurationViewModel(isVideo: false, duration: "")
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.scaleFactor = scaleFactor
            XCTAssertFalse(sut.shouldShowDurationView)
        }
    }
    
    func testShouldShowDurationDetail_video_validDuration() {
        let sut = PhotoCellVideoDurationViewModel(isVideo: true, duration: "01:00")
        XCTAssertTrue(sut.shouldShowDurationDetail)
    }
    
    func testShouldShowDurationDetail_video_invalidDuration() {
        let sut = PhotoCellVideoDurationViewModel(isVideo: true, duration: "")
        XCTAssertFalse(sut.shouldShowDurationDetail)
    }
    
    func testShouldShowDurationDetail_notVideo_invalidDuration() {
        let sut = PhotoCellVideoDurationViewModel(isVideo: false, duration: "")
        XCTAssertFalse(sut.shouldShowDurationDetail)
    }

}
