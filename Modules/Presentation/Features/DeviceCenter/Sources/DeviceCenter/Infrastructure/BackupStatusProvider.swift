import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

public protocol BackupStatusProviding {
    /// Returns display assets for a simplified backup status.
    func backupDisplayAssets(for status: BackupDisplayStatusEntity) -> StatusAssets?
    /// Returns display assets for a simplified device status.
    func deviceDisplayAssets(for status: DeviceDisplayStatusEntity) -> StatusAssets?
}

public final class BackupStatusProvider: BackupStatusProviding {
    private lazy var backupDisplayAssetsDictionary: [BackupDisplayStatusEntity: StatusAssets] = {
        [
            .inactive: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.Inactive.Status.message,
                color: TokenColors.Text.secondary,
                iconName: BackUpStatusIconAssets.inactive.rawValue
            ),
            .error: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.Error.Status.message,
                color: TokenColors.Text.error,
                iconName: BackUpStatusIconAssets.error.rawValue
            ),
            .disabled: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.Disabled.Status.message,
                color: TokenColors.Text.warning,
                iconName: BackUpStatusIconAssets.disabled.rawValue
            ),
            .paused: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.Paused.Status.message,
                color: TokenColors.Text.secondary,
                iconName: BackUpStatusIconAssets.paused.rawValue
            ),
            .updating: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.Updating.Status.message,
                color: TokenColors.Text.info,
                iconName: BackUpStatusIconAssets.updating.rawValue
            ),
            .upToDate: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.UpToDate.Status.message,
                color: TokenColors.Text.success,
                iconName: BackUpStatusIconAssets.upToDate.rawValue
            )
        ]
    }()
    
    private lazy var deviceDisplayAssetsDictionary: [DeviceDisplayStatusEntity: StatusAssets] = {
        [
            .inactive: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.Inactive.Status.message,
                color: TokenColors.Text.secondary,
                iconName: BackUpStatusIconAssets.inactive.rawValue
            ),
            .attentionNeeded: StatusAssets(
                title: Strings.Localizable.Device.Center.Device.AttentionNeeded.Status.message,
                color: TokenColors.Text.error,
                iconName: BackUpStatusIconAssets.attentionNeeded.rawValue
            ),
            .updating: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.Updating.Status.message,
                color: TokenColors.Text.info,
                iconName: BackUpStatusIconAssets.updating.rawValue
            ),
            .upToDate: StatusAssets(
                title: Strings.Localizable.Device.Center.Backup.UpToDate.Status.message,
                color: TokenColors.Text.success,
                iconName: BackUpStatusIconAssets.upToDate.rawValue
            )
        ]
    }()
    
    public init() { }
    
    public func backupDisplayAssets(for status: BackupDisplayStatusEntity) -> StatusAssets? {
        backupDisplayAssetsDictionary[status]
    }
    
    public func deviceDisplayAssets(for status: DeviceDisplayStatusEntity) -> StatusAssets? {
        deviceDisplayAssetsDictionary[status]
    }
    
    /// Enum representing the backup status icon assets.
    private enum BackUpStatusIconAssets: String {
        case upToDate, updating, noCameraUploads, disabled, error, paused, outOfQuota, inactive, attentionNeeded
    }
}
