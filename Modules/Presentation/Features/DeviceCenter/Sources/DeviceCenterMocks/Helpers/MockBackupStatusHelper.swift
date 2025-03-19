import DeviceCenter
import MEGADomain

public final class MockBackupStatusProvider: BackupStatusProviding {
    private let stubbedItem: BackupStatus?
    
    public init(stubbedItem: BackupStatus? = nil) {
        self.stubbedItem = stubbedItem
    }
    
    public func backupStatus(for status: BackupStatusEntity) -> BackupStatus? {
        stubbedItem
    }
}
