import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI

protocol BackupStatusFactoryProtocol {
    static func createBackupStatus(status: BackupStatusEntity, title: String, color: UIColor, iconName: String) -> BackupStatus
}

final class BackupStatusFactory: BackupStatusFactoryProtocol {
    static func createBackupStatus(
        status: BackupStatusEntity,
        title: String,
        color: UIColor,
        iconName: String
    ) -> BackupStatus {
        return BackupStatus(
            status: status,
            title: title,
            color: color,
            iconName: iconName
        )
    }
}

final class BackupStatusHelper {
    static var isDesignTokenEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
    }
    
    static func createBackupStatuses() -> [BackupStatus] {
        return [
            BackupStatusFactory.createBackupStatus(
               status: .upToDate,
               title: Strings.Localizable.Device.Center.Backup.UpToDate.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.success : UIColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1.0),
               iconName: BackUpStatusIconAssets.upToDate
            ),
           
           BackupStatusFactory.createBackupStatus(
               status: .scanning,
               title: Strings.Localizable.Device.Center.Backup.Scanning.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.info : UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),
               iconName: BackUpStatusIconAssets.updating),
           
           BackupStatusFactory.createBackupStatus(
               status: .initialising,
               title: Strings.Localizable.Device.Center.Backup.Initialising.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.info : UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),
               iconName: BackUpStatusIconAssets.updating),
           
           BackupStatusFactory.createBackupStatus(
               status: .updating,
               title: Strings.Localizable.Device.Center.Backup.Updating.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.info : UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),
               iconName: BackUpStatusIconAssets.updating),
           
           BackupStatusFactory.createBackupStatus(
               status: .noCameraUploads,
               title: Strings.Localizable.Device.Center.Backup.NoCameraUploads.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.warning : UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0),
               iconName: BackUpStatusIconAssets.noCameraUploads),
           
           BackupStatusFactory.createBackupStatus(
               status: .disabled,
               title: Strings.Localizable.Device.Center.Backup.Disabled.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.warning : UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0),
               iconName: BackUpStatusIconAssets.disabled),
           
           BackupStatusFactory.createBackupStatus(
               status: .offline,
               title: Strings.Localizable.Device.Center.Backup.Offline.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.secondary : UIColor(red: 0.545, green: 0.545, blue: 0.545, alpha: 1.0),
               iconName: BackUpStatusIconAssets.offlineStatus),
           
           BackupStatusFactory.createBackupStatus(
               status: .backupStopped,
               title: Strings.Localizable.Device.Center.Backup.BackupStopped.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.secondary : UIColor(red: 0.545, green: 0.545, blue: 0.545, alpha: 1.0),
               iconName: BackUpStatusIconAssets.error),
           
           BackupStatusFactory.createBackupStatus(
               status: .paused,
               title: Strings.Localizable.Device.Center.Backup.Paused.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.secondary : UIColor(red: 0.545, green: 0.545, blue: 0.545, alpha: 1.0),
               iconName: BackUpStatusIconAssets.paused),
           
           BackupStatusFactory.createBackupStatus(
               status: .outOfQuota,
               title: Strings.Localizable.Device.Center.Backup.OutOfQuota.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.error : UIColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0),
               iconName: BackUpStatusIconAssets.outOfQuota),
           
           BackupStatusFactory.createBackupStatus(
               status: .error,
               title: Strings.Localizable.Device.Center.Backup.Error.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.error : UIColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0),
               iconName: BackUpStatusIconAssets.error),
           
           BackupStatusFactory.createBackupStatus(
               status: .blocked,
               title: Strings.Localizable.Device.Center.Backup.Blocked.Status.message,
               color: isDesignTokenEnabled ? TokenColors.Text.error : UIColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0),
               iconName: BackUpStatusIconAssets.disabled)
        ]
    }
    
    private struct BackUpStatusIconAssets {
        static let upToDate = "backUpStatusUpToDate"
        static let updating = "backUpStatusUpdating"
        static let noCameraUploads = "backUpStatusNoCameraUploads"
        static let disabled  = "backUpStatusDisabled"
        static let offlineStatus = "backUpStatusOfflineStatus"
        static let error = "backUpStatusError"
        static let paused = "backUpStatusPaused"
        static let outOfQuota = "backUpStatusOutOfQuota"
    }
}
