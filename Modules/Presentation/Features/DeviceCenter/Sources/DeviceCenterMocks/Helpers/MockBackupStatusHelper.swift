import DeviceCenter
import MEGADomain

public final class MockBackupStatusProvider: BackupStatusProviding {
    public var stubbedBackupDisplayAssets: StatusAssets?
    public var stubbedDeviceDisplayAssets: StatusAssets?
    
    public init(stubbedBackupDisplayAssets: StatusAssets? = nil,
                stubbedDeviceDisplayAssets: StatusAssets? = nil) {
        self.stubbedBackupDisplayAssets = stubbedBackupDisplayAssets
        self.stubbedDeviceDisplayAssets = stubbedDeviceDisplayAssets
    }
    
    public func backupDisplayAssets(for status: BackupDisplayStatusEntity) -> StatusAssets? {
        stubbedBackupDisplayAssets
    }
    
    public func deviceDisplayAssets(for status: DeviceDisplayStatusEntity) -> StatusAssets? {
        stubbedDeviceDisplayAssets
    }
}
