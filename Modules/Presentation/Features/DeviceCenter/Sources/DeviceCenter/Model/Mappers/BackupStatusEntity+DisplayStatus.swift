import MEGADomain

extension BackupEntity {
    func toDisplayStatus() -> BackupDisplayStatusEntity? {
        switch backupStatus {
        case .inactive: .inactive
        case .disabled: type == .cameraUpload || type == .mediaUpload ? .disabled : .error
        case .paused: type == .cameraUpload || type == .mediaUpload ? .disabled : .paused
        case .offline, .blocked, .outOfQuota, .error, .backupStopped: .error
        case .updating, .scanning, .initialising: .updating
        case .upToDate: .upToDate
        case .noCameraUploads: .noCameraUploads
        default: nil
        }
    }
}

extension Array where Element == BackupEntity {
    func toDeviceDisplayStatus() -> DeviceDisplayStatusEntity {
        guard let backupStatus = compactMap({$0.toDisplayStatus()})
            .max(by: { $0.priority < $1.priority }) else {
            return .attentionNeeded
        }
        
        return switch backupStatus {
        case .inactive: .inactive
        case .error, .disabled, .paused: .attentionNeeded
        case .updating: .updating
        case .upToDate: .upToDate
        case .noCameraUploads: .noCameraUploads
        }
    }
}

extension BackupDisplayStatusEntity {
    public var priority: Int {
        switch self {
        case .inactive: 0
        case .error: 1
        case .disabled: 2 // Only for CU
        case .paused: 3 // For all backups and sync except CU
        case .updating: 4
        case .upToDate: 5
        case .noCameraUploads: 6 // Only for CU
        }
    }
}
