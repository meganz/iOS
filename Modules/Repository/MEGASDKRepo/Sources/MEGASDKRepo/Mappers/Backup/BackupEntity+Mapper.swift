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
                  userAgent: backupInfo.userAgent ?? "",
                  rootHandle: backupInfo.root,
                  lastHandleSync: backupInfo.lastSync,
                  type: backupInfo.type.toBackupTypeEntity(),
                  localFolder: backupInfo.localFolder ?? "",
                  extra: backupInfo.extra ?? "",
                  syncState: backupInfo.state.toBackUpStateEntity(),
                  substate: backupInfo.substate.toBackupSubstateEntity(),
                  status: backupInfo.status.toBackupHeartbeatStatusEntity(),
                  progress: UInt(backupInfo.progress),
                  uploads: UInt(backupInfo.uploads),
                  downloads: UInt(backupInfo.downloads),
                  timestamp: backupInfo.timestamp,
                  activityTimestamp: backupInfo.activityTimestamp
        )
    }
}
