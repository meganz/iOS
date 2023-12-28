@testable import MEGA
import MEGAL10n
import SwiftUI
import XCTest

class CameraUploadBannerStatusViewStatesToPreviewEntityTests: XCTestCase {
    
    typealias ColorSchemeColors = (light: Color, dark: Color)
    
    func testToPreviewEntitty_ForAllUploadCompletedStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadCompleted,
            textColor: (.primary, .primary),
            backgroundColor: (MEGAAppColor.White._FFFFFF.color, MEGAAppColor.Gray._1D1D1D.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.subHeading
        )
    }
    
    func testToPreviewEntity_ForAllInProgressStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadInProgress(numberOfFilesPending: 1),
            textColor: (.primary, .primary),
            backgroundColor: (MEGAAppColor.White._FFFFFF.color, MEGAAppColor.Gray._1D1D1D.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadInProgress.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(1)
        )
        
        performPreviewComparisonTest(
            status: .uploadInProgress(numberOfFilesPending: 12),
            textColor: (.primary, .primary),
            backgroundColor: (MEGAAppColor.White._FFFFFF.color, MEGAAppColor.Gray._1D1D1D.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadInProgress.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(12)
        )
    }
    
    func testToPreviewEntity_ForAllInUploadPausedStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 1)),
            textColor: (.primary, .primary),
            backgroundColor: (MEGAAppColor.White._FFFFFF.color, MEGAAppColor.Gray._1D1D1D.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsPausedDueToWifi.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(1)
        )
        
        performPreviewComparisonTest(
            status: .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 13)),
            textColor: (.primary, .primary),
            backgroundColor: (MEGAAppColor.White._FFFFFF.color, MEGAAppColor.Gray._1D1D1D.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsPausedDueToWifi.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(13)
        )
    }
    
    func testToPreviewEntity_ForAllInUploadPartiallyCompletedStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadPartialCompleted(reason: .photoLibraryLimitedAccess),
            textColor: (MEGAAppColor.Yellow._9D8319.color, MEGAAppColor.Yellow._FFD60A.color),
            backgroundColor: (MEGAAppColor.Yellow._FED42926.color, MEGAAppColor.Yellow._FED42926.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.LimitedPhotoLibraryAccess.subHeading
        )
        
        performPreviewComparisonTest(
            status: .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 1)),
            textColor: (.primary, .primary),
            backgroundColor: (MEGAAppColor.White._FFFFFF.color, MEGAAppColor.Gray._1D1D1D.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.VideosNotUploaded.subHeading(1)
        )
        
        performPreviewComparisonTest(
            status: .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 42)),
            textColor: (.primary, .primary),
            backgroundColor: (MEGAAppColor.White._FFFFFF.color, MEGAAppColor.Gray._1D1D1D.color),
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.VideosNotUploaded.subHeading(42)
        )
    }
    
    func performPreviewComparisonTest(
        status: CameraUploadBannerStatusViewStates,
        textColor: ColorSchemeColors,
        backgroundColor: ColorSchemeColors,
        expectedTitle: String,
        expectedSubheading: String,
        file: StaticString = #filePath,
        line: UInt = #line) {
        
        // Act
        let previewEntity = status.toPreviewEntity()
        
        // Assert
        XCTAssertEqual(previewEntity.title, expectedTitle, "For status: \(status)", file: file, line: line)
        XCTAssertEqual(previewEntity.subheading, expectedSubheading, "For status: \(status)", file: file, line: line)
        XCTAssertEqual(textColor.light, previewEntity.textColor(for: .light), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(textColor.dark, previewEntity.textColor(for: .dark), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(backgroundColor.light, previewEntity.backgroundColor(for: .light), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(backgroundColor.dark, previewEntity.backgroundColor(for: .dark), "For status: \(status)", file: file, line: line)
    }
}
