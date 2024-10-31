@testable import ContentLibraries
import XCTest

final class PhotoCellVideoDurationViewModelTests: XCTestCase {
    func testShouldShowDurationDetail_video_validDuration() {
        let sut = PhotoCellVideoDurationViewModel(isVideo: true, duration: "01:00")
        XCTAssertTrue(sut.shouldShowDuration)
    }
    
    func testShouldShowDurationDetail_video_invalidDuration() {
        let sut = PhotoCellVideoDurationViewModel(isVideo: true, duration: "")
        XCTAssertFalse(sut.shouldShowDuration)
    }
    
    func testShouldShowDurationDetail_notVideo_invalidDuration() {
        let sut = PhotoCellVideoDurationViewModel(isVideo: false, duration: "")
        XCTAssertFalse(sut.shouldShowDuration)
    }
    
    func testDurationYOffset_scaleFactor_correctOffset() {
        var sut = PhotoCellVideoDurationViewModel(isVideo: true, duration: "01:00")
        
        [(PhotoLibraryZoomState.ScaleFactor.one, -6),
         (.three, -5),
         (.five, -2),
         (.thirteen, 0)
        ].forEach {
            sut.scaleFactor = $0.0
            
            XCTAssertEqual(sut.durationYOffset, $0.1)
        }
    }

}
