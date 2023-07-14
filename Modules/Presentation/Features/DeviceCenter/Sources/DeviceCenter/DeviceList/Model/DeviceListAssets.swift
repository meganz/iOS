import MEGADomain

public struct DeviceListAssets {
    public let title: String
    public let currentDeviceTitle: String
    public let otherDevicesTitle: String
    public let backupStatuses: [BackupStatus]
    
    public var sortedBackupStatuses: [BackupStatusEntity: BackupStatus] {
        return Dictionary(uniqueKeysWithValues: backupStatuses.map { ($0.status, $0) })
    }
    
    public init(title: String, currentDeviceTitle: String, otherDevicesTitle: String, backupStatuses: [BackupStatus]) {
        self.title = title
        self.currentDeviceTitle = currentDeviceTitle
        self.otherDevicesTitle = otherDevicesTitle
        self.backupStatuses = backupStatuses
    }
}
