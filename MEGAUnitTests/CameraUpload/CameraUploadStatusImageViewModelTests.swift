@testable import MEGA
import MEGADesignToken
import SwiftUI
import XCTest

final class CameraUploadStatusImageViewModelTests: XCTestCase {
    
    func testStatusImageResource_onStatus_shouldReturnCorrectImageResource() {
        let expectations: [(CameraUploadStatus, MEGA.ImageResource?)] = [
            (.turnedOff, nil),
            (.checkPendingItemsToUpload, .cuStatusUploadSync),
            (.uploading(progress: 0.65), .cuStatusUploadInProgressCheckMark),
            (.completed, .cuStatusUploadCompleteGreenCheckMark),
            (.idle, .cuStatusUploadIdleCheckMark),
            (.warning, .cuStatusUploadWarningCheckMark)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = CameraUploadStatusImageViewModel(status: status)
                XCTAssertEqual(sut.statusImageResource, expectedResult)
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
        let uploadingColor = UIColor.isDesignTokenEnabled() ?
            TokenColors.Support.info.swiftUI :
            Color(.cameraUploadStatusUploading)
        let completedColor = UIColor.isDesignTokenEnabled() ?
            TokenColors.Support.success.swiftUI :
            Color(.cameraUploadStatusCompleted)
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
        let expectations: [(CameraUploadStatus, MEGA.ImageResource?)] = [
            (.turnedOff, .cuStatusEnable),
            (.checkPendingItemsToUpload, .cuStatusUpload),
            (.uploading(progress: 0.65), .cuStatusUpload),
            (.completed, .cuStatusUpload),
            (.idle, .cuStatusUpload),
            (.warning, .cuStatusUpload)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = CameraUploadStatusImageViewModel(status: status)
                XCTAssertEqual(sut.baseImageResource, expectedResult)
            }
    }
}
