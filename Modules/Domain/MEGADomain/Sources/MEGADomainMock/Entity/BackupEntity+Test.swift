import Foundation
import MEGADomain

public extension BackupEntity {
    init(id: Int = 0,
         name: String = "",
         deviceId: String = "",
         rootHandle: HandleEntity = .invalid,
         lastHandleSync: HandleEntity = .invalid,
         type: BackupTypeEntity = .invalid,
         localFolder: String = "",
         extra: String = "",
         syncState: SyncStateEntity = .unknown,
         substate: Int = 0,
         status: Int = 0,
         progress: Int = 0,
         uploads: Int = 0,
         downloads: Int = 0,
         timestamp: Date = Date(),
         activityTimestamp: Date = Date(),
         isTesting: Bool = true) {
        self.init(
            id: id,
            name: name,
            deviceId: deviceId,
            rootHandle: rootHandle,
            lastHandleSync: lastHandleSync,
            type: type,
            localFolder: localFolder,
            extra: extra,
            syncState: syncState,
            substate: substate,
            status: status,
            progress: progress,
            uploads: uploads,
            downloads: downloads,
            timestamp: timestamp,
            activityTimestamp: activityTimestamp
        )
    }
}
