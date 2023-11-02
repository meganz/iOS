@testable import MEGA
import SwiftUI
import XCTest

final class CameraUploadStatusButtonViewModelTests: XCTestCase {
    func testStatusImageResource_onStatus_shouldReturnCorrectImageResource() {
        let expectations: [(CameraUploadStatus, MEGA.ImageResource?)] = [
            (.enable, nil),
            (.sync, .cuStatusUploadSync),
            (.uploading(progress: 0.65), .cuStatusUploadInProgressCheckMark),
            (.completed, .cuStatusUploadCompleteGreenCheckMark),
            (.idle, .cuStatusUploadIdleCheckMark),
            (.warning, .cuStatusUploadWarningCheckMark)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = makeSUT(initialStatus: status)
                XCTAssertEqual(sut.statusImageResource, expectedResult)
            }
    }
    
    func testProgress_onUploading_progressShouldBeCorrect() throws {
        let expectedProgress: Float = 0.65
        let sut = makeSUT(initialStatus: .uploading(progress: expectedProgress))
        
        let progress = try XCTUnwrap(sut.progress)
        XCTAssertEqual(progress, progress, accuracy: 0.1)
    }
    
    func testProgress_onCompleted_progressShouldBeCorrect() throws {
        let sut = makeSUT(initialStatus: .completed)
        
        let progress = try XCTUnwrap(sut.progress)
        XCTAssertEqual(progress, 1.0, accuracy: 0.1)
    }
    
    func testProgress_onOtherStatuses_shouldBeNil() {
        [CameraUploadStatus.enable, .sync, .idle, .warning].forEach {
            let sut = makeSUT(initialStatus: $0)
            XCTAssertNil(sut.progress)
        }
    }
    
    func testProgressLineColor_onStatus_colorShouldBeCorrect() {
        let expectations: [(CameraUploadStatus, Color)] = [
            (.enable, .clear),
            (.sync, .clear),
            (.uploading(progress: 0.65), Color(Colors.General.Blue._007Aff.color)),
            (.completed, Color(Colors.General.Green._34C759.color)),
            (.idle, .clear),
            (.warning, .clear)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = makeSUT(initialStatus: status)
                XCTAssertEqual(sut.progressLineColor, expectedResult)
            }
    }
    
    func testShouldRotateStatusImage_onStatus_colorShouldBeCorrect() {
        let expectations: [(CameraUploadStatus, Bool)] = [
            (.enable, false),
            (.sync, true)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = makeSUT(initialStatus: status)
                XCTAssertEqual(sut.shouldRotateStatusImage, expectedResult)
            }
    }
    
    func testBaseImageResource_onStatus_shouldReturnCorrectImageResource() {
        let expectations: [(CameraUploadStatus, MEGA.ImageResource?)] = [
            (.enable, .cuStatusEnable),
            (.sync, .cuStatusUpload),
            (.uploading(progress: 0.65), .cuStatusUpload),
            (.completed, .cuStatusUpload),
            (.idle, .cuStatusUpload),
            (.warning, .cuStatusUpload)
        ]
        
        expectations
            .forEach { status, expectedResult in
                let sut = makeSUT(initialStatus: status)
                XCTAssertEqual(sut.baseImageResource, expectedResult)
            }
    }
    
    private func makeSUT(initialStatus: CameraUploadStatus = .sync) -> CameraUploadStatusButtonViewModel {
        CameraUploadStatusButtonViewModel(status: initialStatus)
    }
}
