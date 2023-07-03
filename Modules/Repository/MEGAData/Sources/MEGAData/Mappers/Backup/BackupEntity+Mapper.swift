import Foundation
import MEGADomain
import MEGASdk

extension MEGABackupInfo {
    public func toBackupInfoEntity() -> BackupEntity {
        BackupEntity(backupInfo: self)
    }
}

extension Array where Element == MEGABackupInfo {
    func toBackupInfoEntities() -> [BackupEntity] {
        compactMap { $0.toBackupInfoEntity() }
    }
}

fileprivate extension BackupEntity {
    init(backupInfo: MEGABackupInfo) {
        self.init(id: Int(backupInfo.id),
                  name: backupInfo.name ?? "",
                  deviceId: backupInfo.deviceId ?? "",
                  rootHandle: backupInfo.root,
                  lastHandleSync: backupInfo.lastSync,
                  type: backupInfo.type.toBackupTypeEntity(),
                  localFolder: backupInfo.localFolder ?? "",
                  extra: backupInfo.extra ?? "",
                  syncState: backupInfo.state.toSyncStateEntity(),
                  substate: Int(backupInfo.substate),
                  status: Int(backupInfo.status),
                  progress: Int(backupInfo.progress),
                  uploads: Int(backupInfo.uploads),
                  downloads: Int(backupInfo.downloads),
                  timestamp: backupInfo.ts ?? Date(),
                  activityTimestamp: backupInfo.activityTs ?? Date()
        )
    }
}
