import DeviceCenter

public final class MockBackupStatusProvider: BackupStatusProviding {
    private let statuses: [BackupStatus]
    
    public init(statuses: [BackupStatus]) {
        self.statuses = statuses
    }
    
    public func createBackupStatuses() -> [BackupStatus] {
        statuses
    }
}
