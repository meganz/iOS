import MEGADomain
import MEGASdk
import MEGASwift

public struct DeviceCenterRepository: DeviceCenterRepositoryProtocol {
    public static var newRepo: DeviceCenterRepository {
        DeviceCenterRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func fetchUserDevices() async -> [DeviceEntity] {
        let deviceNamesDictionary = await fetchUserDeviceNames()
        let userBackups = await fetchUserBackups()
        let userGroupedBackups = Dictionary(grouping: userBackups, by: \.deviceId)
        
        return userGroupedBackups.keys.compactMap { deviceId in
            guard let deviceBackups = userGroupedBackups[deviceId],
                  let deviceName = deviceNamesDictionary[deviceId],
                    deviceBackups.isNotEmpty else { return nil }
            
            let backups = updateBackupsWithSyncStatus(deviceBackups)
            
            return DeviceEntity(
                id: deviceId,
                name: deviceName,
                backups: backups,
                status: calculateGlobalStatus(backups)
            )
        }
    }
    
    public func fetchDeviceNames() async -> [String] {
        await fetchUserDevices().compactMap { $0.name }
    }
    
    public func loadCurrentDeviceId() -> String? {
        sdk.deviceId()
    }
    
    private func fetchUserBackups() async -> [BackupEntity] {
        await withAsyncValue(in: { completion in
            sdk.getBackupInfo(RequestDelegate(completion: { result in
                if case let .success(request) = result {
                    completion(.success(request.backupInfoList?.toBackupInfoEntities() ?? []))
                } else {
                    completion(.success([]))
                }
            }))
        })
    }
    
    private func fetchUserDeviceNames() async -> [String: String] {
        await withAsyncValue(in: { completion in
            sdk.getUserAttributeType(.deviceNames, delegate: RequestDelegate { (result) in
                if case let .success(request) = result {
                    guard let devicesDictionary = request.megaStringDictionary else { return }
                    
                    let devices = devicesDictionary.mapValues { value in
                        guard let deviceName = value.base64URLDecoded else { return "" }
                        return deviceName
                    }
                    
                    completion(.success(devices))
                } else {
                    completion(.success([:]))
                }
            })
        })
    }
    
    private func calculateGlobalStatus(_ backups: [BackupEntity]) -> BackupStatusEntity? {
        backups
            .compactMap {$0.backupStatus}
            .max {$0.priority < $1.priority}
    }
    
    private func updateBackupsWithSyncStatus(_ backups: [BackupEntity]) -> [BackupEntity] {
        let currentDate = Date().timeIntervalSince1970
        let maxLastHeartbeatTimeForMobiles: Double = 3600.0
        let maxLastSyncTimeForOtherDevices: Double = 1800.0
        
        return backups.map { backup in
            var updatedBackup = backup
            var backupSyncState: BackupStatusEntity?
            var lastBackupHeartbeat: TimeInterval = 0
            
            let isMobileBackup = backup.type == .mediaUpload || backup.type == .cameraUpload
            
            lastBackupHeartbeat = max(
                (backup.timestamp?.timeIntervalSince1970 ?? 0),
                (backup.activityTimestamp?.timeIntervalSince1970 ?? 0)
            )
            
            let timeSinceLastInteractionInSeconds = currentDate - lastBackupHeartbeat
            
            let lastInteractionOutOfRange = (isMobileBackup && timeSinceLastInteractionInSeconds > maxLastHeartbeatTimeForMobiles) || !isMobileBackup && timeSinceLastInteractionInSeconds > maxLastSyncTimeForOtherDevices
            
            switch backup.syncState {
            case .unknown:
                backupSyncState = .backupStopped
            case .failed, .temporaryDisabled:
                switch backup.substate {
                case .storageOverquota:
                    backupSyncState = .outOfQuota
                case .accountExpired, .accountBlocked, .noSyncError:
                    backupSyncState = .blocked
                default:
                    backupSyncState = .error
                }
            case .pauseDown:
                backupSyncState = .paused
            case .disabled:
                backupSyncState = .disabled
            default:
                if lastBackupHeartbeat == 0 || lastInteractionOutOfRange {
                    let backupOlderThan10Minutes = currentDate - (backup.timestamp?.timeIntervalSince1970 ?? 0) > 600
                    let currentBackupFolderExists = backup.rootHandle != .invalid
                    
                    if currentBackupFolderExists || backupOlderThan10Minutes {
                        backupSyncState = .offline
                    }
                } else if backup.isPaused() {
                    backupSyncState = .paused
                } else {
                    switch backup.status {
                    case .upToDate, .inactive:
                        if backup.syncState == .active || backup.syncState.isPaused() {
                            backupSyncState = .upToDate
                        }
                    case .unknown:
                        backupSyncState = .initialising
                    case .syncing:
                        backupSyncState = .updating
                    case .pending:
                        backupSyncState = .scanning
                    }
                }
            }
            
            updatedBackup.backupStatus = backupSyncState
            
            return updatedBackup
        }
    }
}
