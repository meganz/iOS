import Foundation
import MEGAL10n
import MEGASwiftUI
import SwiftUI

extension CameraUploadBannerStatusViewStates {
    func toPreviewEntity() -> CameraUploadBannerStatusViewPreviewEntity {
        CameraUploadBannerStatusViewPreviewEntity(
            title: title,
            subheading: subheading, 
            textColor: textColor,
            backgroundColor: backgroundColor)
    }
}

extension CameraUploadBannerStatusViewStates: CameraUploadBannerStatusViewPresenterProtocol {
    var title: String {
        switch self {
        case .uploadInProgress:
            return Strings.Localizable.CameraUploads.Banner.Status.UploadInProgress.title
        case .uploadCompleted:
            return Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title
        case .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
                .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.title
        }
    }
    
    var subheading: String {
        switch self {
        case .uploadInProgress(let numberOfFilesPending):
            return Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(numberOfFilesPending)
        case .uploadCompleted:
            return Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.subHeading
        case .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
                .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.subheading
        }
    }

    var textColor: AnyShapeStyle {
        switch self {
        case .uploadInProgress, .uploadCompleted:
            return Color.primary.toAnyShapeStyle()
        case .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
                .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.textColor
        }
    }
    
    var backgroundColor: AnyShapeStyle {
        switch self {
        case .uploadInProgress, .uploadCompleted:
            return ColorSchemeDesiredColor(lightMode: .white, darkMode: ._1_D_1_D_1_D).toAnyShapeStyle()
        case .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
                .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.backgroundColor
        }
    }
}

extension CameraUploadBannerStatusPartiallyCompletedReason: CameraUploadBannerStatusViewPresenterProtocol {
    var title: String {
        switch self {
        case .photoLibraryLimitedAccess, .videoUploadIsNotEnabled:
            return Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.title
        }
    }
    
    var subheading: String {
        switch self {
        case .videoUploadIsNotEnabled(let pendingVideoUploadCount):
            return Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.VideosNotUploaded.subHeading(pendingVideoUploadCount)
        case .photoLibraryLimitedAccess:
            return Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.LimitedPhotoLibraryAccess.subHeading
        }
    }
    
    var textColor: AnyShapeStyle {
        switch self {
        case .videoUploadIsNotEnabled:
            return Color.primary.toAnyShapeStyle()
        case .photoLibraryLimitedAccess:
            return ColorSchemeDesiredColor(lightMode: .yellow9D8319, darkMode: .yellowFFD60A).toAnyShapeStyle()
        }
    }
    
    var backgroundColor: AnyShapeStyle {
        switch self {
        case .videoUploadIsNotEnabled:
            return ColorSchemeDesiredColor(lightMode: .white, darkMode: ._1_D_1_D_1_D).toAnyShapeStyle()
        case .photoLibraryLimitedAccess:
            return Color.yellowFED42926.toAnyShapeStyle()
        }
    }
}

extension CameraUploadBannerStatusUploadPausedReason: CameraUploadBannerStatusViewPresenterProtocol {
    var title: String {
        switch self {
        case .noWifiConnection:
            return Strings.Localizable.CameraUploads.Banner.Status.UploadsPausedDueToWifi.title
        }
    }
    
    var subheading: String {
        switch self {
        case .noWifiConnection(let numberOfFilesPending):
            return Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(numberOfFilesPending)
        }
    }
    
    var textColor: AnyShapeStyle { Color.primary.toAnyShapeStyle() }
    
    var backgroundColor: AnyShapeStyle {
        ColorSchemeDesiredColor(lightMode: .white, darkMode: ._1_D_1_D_1_D)
            .toAnyShapeStyle()
    }
}
