@testable import MEGA
import MEGADesignToken
import MEGAL10n
import SwiftUI
import XCTest

final class CameraUploadBannerStatusViewStatesToPreviewEntityTests: XCTestCase {

    private typealias ColorSchemeColors = (light: Color, dark: Color)

    func testToPreviewEntitty_ForAllUploadCompletedStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadCompleted,
            legacyTextColor: (.primary, .primary),
            legacyBackgroundColor: (UIColor.whiteFFFFFF.swiftUI, UIColor.gray1D1D1D.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Background.page.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: { .init(Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.subHeading) }
        )
    }
    
    func testToPreviewEntity_ForAllInProgressStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadInProgress(numberOfFilesPending: 1),
            legacyTextColor: (.primary, .primary),
            legacyBackgroundColor: (UIColor.whiteFFFFFF.swiftUI, UIColor.gray1D1D1D.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Background.page.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadInProgress.title,
            expectedSubheading: { .init(Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(1)) }
        )

        performPreviewComparisonTest(
            status: .uploadInProgress(numberOfFilesPending: 12),
            legacyTextColor: (.primary, .primary),
            legacyBackgroundColor: (UIColor.whiteFFFFFF.swiftUI, UIColor.gray1D1D1D.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Background.page.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadInProgress.title,
            expectedSubheading: { .init(Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(12)) }
        )
    }
    
    func testToPreviewEntity_ForAllInUploadPausedStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 1)),
            legacyTextColor: (.primary, .primary),
            legacyBackgroundColor: (UIColor.whiteFFFFFF.swiftUI, UIColor.gray1D1D1D.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Background.page.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsPausedDueToWifi.title,
            expectedSubheading: { .init(Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(1)) }
        )

        performPreviewComparisonTest(
            status: .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 13)),
            legacyTextColor: (.primary, .primary),
            legacyBackgroundColor: (UIColor.whiteFFFFFF.swiftUI, UIColor.gray1D1D1D.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Background.page.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsPausedDueToWifi.title,
            expectedSubheading: { .init(Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(13)) }
        )
    }
    
    func testToPreviewEntity_ForAllInUploadPartiallyCompletedStates_shouldReturnCorrectStrings() {
        performPreviewComparisonTest(
            status: .uploadPartialCompleted(reason: .photoLibraryLimitedAccess),
            legacyTextColor: (UIColor.yellow9D8319.swiftUI, UIColor.yellowFFD60A.swiftUI),
            legacyBackgroundColor: (UIColor.yellowFED42926.swiftUI, UIColor.yellowFED42926.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Notifications.notificationWarning.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: {
                let subHeading = AttributedString(Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.LimitedPhotoLibraryAccess.subHeading)
                var subHeadingAction = AttributedString(Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.LimitedPhotoLibraryAccess.subHeadingAction)
                subHeadingAction.font = .caption2.bold()
                return subHeading + " " + subHeadingAction
            }
        )

        performPreviewComparisonTest(
            status: .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 1)),
            legacyTextColor: (.primary, .primary),
            legacyBackgroundColor: (UIColor.whiteFFFFFF.swiftUI, UIColor.gray1D1D1D.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Background.page.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: { .init(Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.VideosNotUploaded.subHeading(1)) }
        )

        performPreviewComparisonTest(
            status: .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 42)),
            legacyTextColor: (.primary, .primary),
            legacyBackgroundColor: (UIColor.whiteFFFFFF.swiftUI, UIColor.gray1D1D1D.swiftUI),
            designTokenTextColor: TokenColors.Text.primary.swiftUI,
            designTokenBackgroundColor: TokenColors.Background.page.swiftUI,
            expectedTitle: Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title,
            expectedSubheading: { .init(Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.VideosNotUploaded.subHeading(42)) }
        )
    }

    private func performPreviewComparisonTest(
        status: CameraUploadBannerStatusViewStates,
        legacyTextColor: ColorSchemeColors,
        legacyBackgroundColor: ColorSchemeColors,
        designTokenTextColor: Color,
        designTokenBackgroundColor: Color,
        expectedTitle: String,
        expectedSubheading: () -> AttributedString,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Semantic Colors
        performPreviewComparisonTest(
            status: status,
            textColor: (designTokenTextColor, designTokenTextColor),
            backgroundColor: (designTokenBackgroundColor, designTokenBackgroundColor),
            bottomBorderColor: (TokenColors.Border.subtle.swiftUI, TokenColors.Border.subtle.swiftUI),
            expectedTitle: expectedTitle,
            expectedSubheading: expectedSubheading,
            file: file, line: line
        )
    }

    private func performPreviewComparisonTest(
        status: CameraUploadBannerStatusViewStates,
        textColor: ColorSchemeColors,
        backgroundColor: ColorSchemeColors,
        bottomBorderColor: ColorSchemeColors,
        expectedTitle: String,
        expectedSubheading: () -> AttributedString,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Act
        let previewEntity = status.toPreviewEntity()
        
        // Assert
        XCTAssertEqual(previewEntity.title, expectedTitle, "For status: \(status)", file: file, line: line)
        XCTAssertEqual(previewEntity.subheading, expectedSubheading(), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(textColor.light, previewEntity.textColor(for: .light), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(textColor.dark, previewEntity.textColor(for: .dark), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(backgroundColor.light, previewEntity.backgroundColor(for: .light), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(backgroundColor.dark, previewEntity.backgroundColor(for: .dark), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(bottomBorderColor.light, previewEntity.bottomBorder(for: .light), "For status: \(status)", file: file, line: line)
        XCTAssertEqual(bottomBorderColor.dark, previewEntity.bottomBorder(for: .dark), "For status: \(status)", file: file, line: line)
    }
}
