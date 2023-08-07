import MEGADomain
import SwiftUI

public final class BackupListViewModel: ObservableObject {
    
    private let router: any BackupListRouting
    private let backups: [BackupEntity]
    private let backupListAssets: BackupListAssets
    private let backupStatuses: [BackupStatus]
    private var sortedBackupStatuses: [BackupStatusEntity: BackupStatus] {
        Dictionary(uniqueKeysWithValues: backupStatuses.map { ($0.status, $0) })
    }
    private var sortedBackupTypes: [BackupTypeEntity: BackupType] {
        Dictionary(uniqueKeysWithValues: backupListAssets.backupTypes.map { ($0.type, $0) })
    }
    
    @Published private(set) var backupModels: [DeviceCenterItemViewModel] = []
    
    init(
        router: any BackupListRouting,
        backups: [BackupEntity],
        backupListAssets: BackupListAssets,
        backupStatuses: [BackupStatus]
    ) {
        self.router = router
        self.backups = backups
        self.backupListAssets = backupListAssets
        self.backupStatuses = backupStatuses
        
        loadBackupsModels()
    }
    
    func loadBackupsModels() {
        backupModels = backups
            .compactMap { backup in
                if let assets = loadAssets(for: backup) {
                    return DeviceCenterItemViewModel(
                        itemType: .backup(backup),
                        assets: assets
                    )
                }
                return nil
            }
    }
    
    func loadAssets(for backup: BackupEntity) -> ItemAssets? {
        guard let backupStatus = backup.backupStatus,
              let status = sortedBackupStatuses[backupStatus],
              let backupType = sortedBackupTypes[backup.type] else {
            return nil
        }
        
        return ItemAssets(
            iconName: backupType.iconName,
            status: status
        )
    }
}
