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
    
    var subheading: AttributedString {
        switch self {
        case .uploadInProgress(let numberOfFilesPending):
            return .init(Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(Int(numberOfFilesPending)))
        case .uploadCompleted:
            return .init(Strings.Localizable.CameraUploads.Banner.Status.UploadsComplete.subHeading)
        case .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
            .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.subheading
        }
    }
    
    func textColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .uploadInProgress, .uploadCompleted:
            return Color.primary
        case .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
                .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.textColor(for: scheme)
        }
    }
    
    func backgroundColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .uploadInProgress, .uploadCompleted:
            return scheme == .dark ? MEGAAppColor.Gray._1D1D1D.color : MEGAAppColor.White._FFFFFF.color
        case .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
                .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.backgroundColor(for: scheme)
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
    
    var subheading: AttributedString {
        switch self {
        case .videoUploadIsNotEnabled(let pendingVideoUploadCount):
            return .init(Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.VideosNotUploaded.subHeading(Int(pendingVideoUploadCount)))
        case .photoLibraryLimitedAccess:
            let subHeading = AttributedString(Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.LimitedPhotoLibraryAccess.subHeading)
            var subHeadingAction = AttributedString(Strings.Localizable.CameraUploads.Banner.Status.UploadsPartialComplete.LimitedPhotoLibraryAccess.subHeadingAction)
            subHeadingAction.font = .caption2.bold()
            return subHeading + " " + subHeadingAction
        }
    }
    
    func textColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .videoUploadIsNotEnabled:
            return .primary
        case .photoLibraryLimitedAccess:
            return scheme == .dark ? MEGAAppColor.Yellow._FFD60A.color : MEGAAppColor.Yellow._9D8319.color
        }
    }
    
    func backgroundColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .videoUploadIsNotEnabled:
            return scheme == .dark ? MEGAAppColor.Gray._1D1D1D.color : MEGAAppColor.White._FFFFFF.color
        case .photoLibraryLimitedAccess:
            return MEGAAppColor.Yellow._FED42926.color
        }
    }
}

extension CameraUploadBannerStatusUploadPausedReason: CameraUploadBannerStatusViewPresenterProtocol {
    var title: String {
        switch self {
        case .noWifiConnection:
            return Strings.Localizable.CameraUploads.Banner.Status.UploadsPausedDueToWifi.title
        case .noInternetConnection:
            return Strings.Localizable.noInternetConnection
        }
    }
    
    var subheading: AttributedString {
        switch self {
        case .noWifiConnection(let numberOfFilesPending), .noInternetConnection(let numberOfFilesPending):
                .init(Strings.Localizable.CameraUploads.Banner.Status.FilesPending.subHeading(Int(numberOfFilesPending)))
        }
    }
    
    func textColor(for scheme: ColorScheme) -> Color { .primary }
    
    func backgroundColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? MEGAAppColor.Gray._1D1D1D.color : MEGAAppColor.White._FFFFFF.color
    }
}
