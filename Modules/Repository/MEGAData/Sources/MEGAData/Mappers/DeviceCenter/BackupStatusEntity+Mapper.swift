import MEGADomain

extension BackupStatusEntity {
    var priority: Int {
        switch self {
        case .noCameraUploads: return 0
        case .backupStopped: return 1
        case .disabled: return 2
        case .offline: return 3
        case .upToDate: return 4
        case .error: return 5
        case .blocked: return 6
        case .outOfQuota: return 7
        case .paused: return 8
        case .initialising: return 9
        case .scanning: return 10
        case .updating: return 11
        }
    }
}
