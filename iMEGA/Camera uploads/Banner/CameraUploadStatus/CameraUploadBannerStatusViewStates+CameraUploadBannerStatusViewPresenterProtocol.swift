import Foundation
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

extension CameraUploadBannerStatusViewStates {
    func toPreviewEntity() -> CameraUploadBannerStatusViewPreviewEntity {
        CameraUploadBannerStatusViewPreviewEntity(
            title: title,
            subheading: subheading,
            textColor: textColor,
            backgroundColor: backgroundColor
        )
    }
}

extension CameraUploadBannerStatusViewStates {
    // This is so that we can inject the design token value in unit tests
    static var _isDesignTokenEnabled: Bool?

    static var isDesignTokenEnabled: Bool {
        if let overriddenIsDesignTokenEnabled = _isDesignTokenEnabled {
            return overriddenIsDesignTokenEnabled
        } else {
            return UIColor.isDesignTokenEnabled()
        }
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
            if Self.isDesignTokenEnabled {
                return TokenColors.Text.primary.swiftUI
            }

            return Color.primary
        case .uploadPaused(let reason as any CameraUploadBannerStatusViewPresenterProtocol),
                .uploadPartialCompleted(let reason as any CameraUploadBannerStatusViewPresenterProtocol):
            return reason.textColor(for: scheme)
        }
    }
    
    func backgroundColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .uploadInProgress, .uploadCompleted:
            if Self.isDesignTokenEnabled {
                return TokenColors.Background.page.swiftUI
            }

            return scheme == .dark ? UIColor.gray1D1D1D.swiftUI : UIColor.whiteFFFFFF.swiftUI
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
            if CameraUploadBannerStatusViewStates.isDesignTokenEnabled {
                return TokenColors.Text.primary.swiftUI
            }

            return .primary
        case .photoLibraryLimitedAccess:
            if CameraUploadBannerStatusViewStates.isDesignTokenEnabled {
                return TokenColors.Text.primary.swiftUI
            }

            return scheme == .dark ? UIColor.yellowFFD60A.swiftUI : UIColor.yellow9D8319.swiftUI
        }
    }
    
    func backgroundColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .videoUploadIsNotEnabled:
            if CameraUploadBannerStatusViewStates.isDesignTokenEnabled {
                return TokenColors.Background.page.swiftUI
            }

            return scheme == .dark ? UIColor.gray1D1D1D.swiftUI : UIColor.whiteFFFFFF.swiftUI
        case .photoLibraryLimitedAccess:
            if CameraUploadBannerStatusViewStates.isDesignTokenEnabled {
                return TokenColors.Notifications.notificationWarning.swiftUI
            }

            return UIColor.yellowFED42926.swiftUI
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
    
    func textColor(for scheme: ColorScheme) -> Color {
        if CameraUploadBannerStatusViewStates.isDesignTokenEnabled {
            return TokenColors.Text.primary.swiftUI
        }

        return .primary
    }
    
    func backgroundColor(for scheme: ColorScheme) -> Color {
        if CameraUploadBannerStatusViewStates.isDesignTokenEnabled {
            return TokenColors.Background.page.swiftUI
        }

        return scheme == .dark ? UIColor.gray1D1D1D.swiftUI : UIColor.whiteFFFFFF.swiftUI
    }
}
