@testable import MEGA
import MEGAAssets
import MEGADesignToken
import SwiftUI
import XCTest

final class CameraUploadStatusImageViewModelTests: XCTestCase {
    
    func testStatusImageResource_onStatus_shouldReturnCorrectImageResource() {
        let expectations: [(CameraUploadStatus, Image?)] = [
            (.turnedOff, nil),
            (.checkPendingItemsToUpload, MEGAAssets.Image.cuStatusUploadSync),
            (.uploading(progress: 0.65), MEGAAssets.Image.cuStatusUploadInProgressCheckMark),
            (.completed, MEGAAssets.Image.cuStatusUploadCompleteGreenCheckMark),
            (.idle, MEGAAssets.Image.cuStatusUploadIdleCheckMark),
            (.warning, MEGAAssets.Image.cuStatusUploadWarningCheckMark)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = CameraUploadStatusImageViewModel(status: status)
                XCTAssertEqual(sut.statusImage, expectedResult)
            }
    }
    
    func testProgress_onUploading_progressShouldBeCorrect() throws {
        let expectedProgress: Float = 0.65
        let sut = CameraUploadStatusImageViewModel(status: .uploading(progress: expectedProgress))
        
        let progress = try XCTUnwrap(sut.progress)
        XCTAssertEqual(progress, progress, accuracy: 0.1)
    }
    
    func testProgress_onCompleted_progressShouldBeCorrect() throws {
        let sut = CameraUploadStatusImageViewModel(status: .completed)
        
        let progress = try XCTUnwrap(sut.progress)
        XCTAssertEqual(progress, 1.0, accuracy: 0.1)
    }
    
    func testProgress_onOtherStatuses_shouldBeNil() {
        [CameraUploadStatus.turnedOff, .checkPendingItemsToUpload, .idle, .warning].forEach {
            let sut = CameraUploadStatusImageViewModel(status: $0)
            XCTAssertNil(sut.progress)
        }
    }
    
    func testProgressLineColor_onStatus_colorShouldBeCorrect() {
        let uploadingColor = TokenColors.Support.info.swiftUI
        let completedColor = TokenColors.Support.success.swiftUI
        let expectations: [(CameraUploadStatus, Color)] = [
            (.turnedOff, .clear),
            (.checkPendingItemsToUpload, .clear),
            (.uploading(progress: 0.65), uploadingColor),
            (.completed, completedColor),
            (.idle, .clear),
            (.warning, .clear)]
        
        expectations
            .forEach { status, expectedResult in
                let sut = CameraUploadStatusImageViewModel(status: status)
                XCTAssertEqual(sut.progressLineColor, expectedResult)
            }
    }
    
    func testShouldRotateStatusImage_onStatus_statusShouldBeCorrect() {
        let expectations: [(CameraUploadStatus, Bool)] = [
            (.turnedOff, false),
            (.checkPendingItemsToUpload, true)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = CameraUploadStatusImageViewModel(status: status)
                XCTAssertEqual(sut.shouldRotateStatusImage, expectedResult)
            }
    }
    
    func testBaseImageResource_onStatus_shouldReturnCorrectImageResource() {
        let expectations: [(CameraUploadStatus, Image?)] = [
            (.turnedOff, MEGAAssets.Image.cuStatusEnable),
            (.checkPendingItemsToUpload, MEGAAssets.Image.cuStatusUpload),
            (.uploading(progress: 0.65), MEGAAssets.Image.cuStatusUpload),
            (.completed, MEGAAssets.Image.cuStatusUpload),
            (.idle, MEGAAssets.Image.cuStatusUpload),
            (.warning, MEGAAssets.Image.cuStatusUpload)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = CameraUploadStatusImageViewModel(status: status)
                XCTAssertEqual(sut.baseImage, expectedResult)
            }
    }
}
