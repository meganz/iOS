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
        BackupStatus(
            status: status,
            title: title,
            color: color,
            iconName: iconName
        )
    }
}

public protocol BackupStatusProviding {
    func backupStatus(for status: BackupStatusEntity) -> BackupStatus?
}

public final class BackupStatusProvider: BackupStatusProviding {
    private lazy var backupStatusDictionary: [BackupStatusEntity: BackupStatus] = {
        Dictionary(uniqueKeysWithValues: createBackupStatuses().map { ($0.status, $0) })
    }()
    
    public init() {}
    
    public func backupStatus(for status: BackupStatusEntity) -> BackupStatus? {
        backupStatusDictionary[status]
    }
    
    private func createBackupStatuses() -> [BackupStatus] {
        [
            BackupStatus(
                status: .upToDate,
                title: Strings.Localizable.Device.Center.Backup.UpToDate.Status.message,
                color: TokenColors.Text.success,
                iconName: BackUpStatusIconAssets.upToDate.rawValue
            ),
            BackupStatus(
                status: .scanning,
                title: Strings.Localizable.Device.Center.Backup.Scanning.Status.message,
                color: TokenColors.Text.info,
                iconName: BackUpStatusIconAssets.updating.rawValue
            ),
            BackupStatus(
                status: .initialising,
                title: Strings.Localizable.Device.Center.Backup.Initialising.Status.message,
                color: TokenColors.Text.info,
                iconName: BackUpStatusIconAssets.updating.rawValue
            ),
            BackupStatus(
                status: .updating,
                title: Strings.Localizable.Device.Center.Backup.Updating.Status.message,
                color: TokenColors.Text.info,
                iconName: BackUpStatusIconAssets.updating.rawValue
            ),
            BackupStatus(
                status: .noCameraUploads,
                title: Strings.Localizable.Device.Center.Backup.NoCameraUploads.Status.message,
                color: TokenColors.Text.warning,
                iconName: BackUpStatusIconAssets.noCameraUploads.rawValue
            ),
            BackupStatus(
                status: .disabled,
                title: Strings.Localizable.Device.Center.Backup.Disabled.Status.message,
                color: TokenColors.Text.warning,
                iconName: BackUpStatusIconAssets.disabled.rawValue
            ),
            BackupStatus(
                status: .offline,
                title: Strings.Localizable.Device.Center.Backup.Offline.Status.message,
                color: TokenColors.Text.secondary,
                iconName: BackUpStatusIconAssets.offline.rawValue
            ),
            BackupStatus(
                status: .backupStopped,
                title: Strings.Localizable.Device.Center.Backup.BackupStopped.Status.message,
                color: TokenColors.Text.secondary,
                iconName: BackUpStatusIconAssets.error.rawValue
            ),
            BackupStatus(
                status: .paused,
                title: Strings.Localizable.Device.Center.Backup.Paused.Status.message,
                color: TokenColors.Text.secondary,
                iconName: BackUpStatusIconAssets.paused.rawValue
            ),
            BackupStatus(
                status: .outOfQuota,
                title: Strings.Localizable.Device.Center.Backup.OutOfQuota.Status.message,
                color: TokenColors.Text.error,
                iconName: BackUpStatusIconAssets.outOfQuota.rawValue
            ),
            BackupStatus(
                status: .error,
                title: Strings.Localizable.Device.Center.Backup.Error.Status.message,
                color: TokenColors.Text.error,
                iconName: BackUpStatusIconAssets.error.rawValue
            ),
            BackupStatus(
                status: .blocked,
                title: Strings.Localizable.Device.Center.Backup.Blocked.Status.message,
                color: TokenColors.Text.error,
                iconName: BackUpStatusIconAssets.disabled.rawValue
            )
        ]
    }
    
    private enum BackUpStatusIconAssets: String {
        case upToDate, updating, noCameraUploads, disabled, offline, error, paused, outOfQuota
    }
}
