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
    
    /// Updates an array of BackupEntity objects with their corresponding sync status.
    ///
    /// This function iterates over the provided list of backups, determines the appropriate sync status based on each backup's
    /// current sync state, substate, last activity, etc., and then updates the backup's status accordingly.
    ///
    /// Additionally, if a backup has had no activity for a duration longer than the specified inactive backup limit,
    /// it will be marked as inactive.
    ///
    /// - Parameters:
    ///   - backups: An array of BackupEntity objects to be updated.
    ///   - currentTime: The reference time (in seconds since 1970) used to evaluate backup activity. Defaults to the current time.
    ///   - inactiveLimit: The time interval (in seconds) after which a backup is considered inactive if no activity is detected.
    ///     Defaults to 60 days in seconds ("60 * 24 * 60 * 60").
    /// - Returns: An updated array of BackupEntity objects with their backupStatus field set based on the evaluation logic.
    private func updateBackupsWithSyncStatus(
        _ backups: [BackupEntity],
        currentTime: TimeInterval = Date().timeIntervalSince1970,
        inactiveLimit: TimeInterval = 60 * 24 * 60 * 60 // 60 days in seconds
    ) -> [BackupEntity] {
        backups.map { backup in
            var updatedBackup = backup
            
            if currentTime - backup.lastBackupHeartbeat > inactiveLimit {
                updatedBackup.backupStatus = .inactive
                return updatedBackup
            }

            updatedBackup.backupStatus = {
                switch backup.syncState {
                case .unknown:
                    return .backupStopped
                case .failed, .temporaryDisabled:
                    switch backup.substate {
                    case .storageOverquota:
                        return .outOfQuota
                    case .accountExpired, .accountBlocked, .noSyncError:
                        return .blocked
                    default:
                        return .error
                    }
                case .pauseDown:
                    return .paused
                case .disabled:
                    return .disabled
                default:
                    if backup.lastBackupHeartbeat == 0 || backup.lastInteractionOutOfRange(from: currentTime) {
                        let isBackupOlderThan10Minutes = currentTime - (backup.timestamp?.timeIntervalSince1970 ?? 0) > 600
                        if backup.rootHandle != .invalid || isBackupOlderThan10Minutes {
                            return .offline
                        }
                    } else if backup.isPaused {
                        return .paused
                    } else {
                        switch backup.status {
                        case .upToDate, .inactive:
                            if backup.syncState == .active || backup.syncState.isPaused {
                                return .upToDate
                            }
                        case .stalled:
                            return .blocked
                        case .unknown:
                            return .initialising
                        case .syncing:
                            return .updating
                        case .pending:
                            return .scanning
                        }
                    }
                    return nil
                }
            }()

            return updatedBackup
        }
    }
}
