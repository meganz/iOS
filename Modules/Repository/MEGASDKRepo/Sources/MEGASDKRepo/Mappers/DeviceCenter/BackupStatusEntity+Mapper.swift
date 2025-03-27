import MEGADomain

extension BackupStatusEntity {
    public var priority: Int {
        return switch self {
        case .inactive: 0
        case .noCameraUploads: 1
        case .backupStopped: 2
        case .disabled: 3
        case .offline: 4
        case .upToDate: 5
        case .error: 6
        case .blocked: 7
        case .outOfQuota: 8
        case .paused: 9
        case .initialising: 10
        case .scanning: 11
        case .updating: 12
        }
    }
}
