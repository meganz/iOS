import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

extension WarningBannerType {
    var title: String? {
        switch self {
        case .fullStorageOverQuota: Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.title
        case .almostFullStorageOverQuota: Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.title
        default: nil
        }
    }

    var icon: Image? {
        switch self {
        case .fullStorageOverQuota: MEGAAssets.Image.fullStorageAlert
        case .almostFullStorageOverQuota: MEGAAssets.Image.almostFullStorageAlert
        default: nil
        }
    }

    var iconColor: Color {
        switch severity {
        case .warning: TokenColors.Support.warning.swiftUI
        case .critical: TokenColors.Support.error.swiftUI
        }
    }

    var actionText: String? {
        switch self {
        case .fullStorageOverQuota: Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.button
        case .almostFullStorageOverQuota: Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.button
        default: nil
        }
    }

    var severity: Severity {
        switch self {
        case .fullStorageOverQuota: .critical
        default: .warning
        }
    }

    var description: String {
        switch self {
        case .noInternetConnection:
            return Strings.Localizable.General.noIntenerConnection
        case .limitedPhotoAccess:
            return Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage
        case .contactsNotVerified:
            return Strings.Localizable.ShareFolder.contactsNotVerified
        case .contactNotVerifiedSharedFolder(let nodeName):
            return Strings.Localizable.SharedItems.ContactVerification.contactNotVerifiedBannerMessage(nodeName)
        case .backupStatusError(let errorMessage):
            return errorMessage
        case .fullStorageOverQuota:
            return Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.description
        case .almostFullStorageOverQuota:
            return Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.description
        }
    }
}
