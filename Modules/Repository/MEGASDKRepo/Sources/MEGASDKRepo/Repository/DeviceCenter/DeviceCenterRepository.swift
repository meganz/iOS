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
    
    private func updateBackupsWithSyncStatus(
        _ backups: [BackupEntity],
        currentTime: TimeInterval = Date().timeIntervalSince1970
    ) -> [BackupEntity] {
        backups.map { backup in
            var updatedBackup = backup

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
                        let backupOlderThan10Minutes = currentTime - (backup.timestamp?.timeIntervalSince1970 ?? 0) > 600
                        if backup.rootHandle != .invalid || backupOlderThan10Minutes {
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
