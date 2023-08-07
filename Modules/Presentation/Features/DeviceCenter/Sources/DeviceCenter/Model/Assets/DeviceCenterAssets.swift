import MEGADomain

public struct DeviceCenterAssets {
    public let deviceListAssets: DeviceListAssets
    public let backupListAssets: BackupListAssets
    public let backupStatuses: [BackupStatus]
    
    public init(deviceListAssets: DeviceListAssets, backupListAssets: BackupListAssets, backupStatuses: [BackupStatus]) {
        self.deviceListAssets = deviceListAssets
        self.backupListAssets = backupListAssets
        self.backupStatuses = backupStatuses
    }
}
