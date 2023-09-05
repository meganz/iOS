import MEGADomain

public struct DeviceCenterAssets {
    public let deviceListAssets: DeviceListAssets
    public let backupListAssets: BackupListAssets
    public let emptyStateAssets: EmptyStateAssets
    public let searchAssets: SearchAssets
    public let backupStatuses: [BackupStatus]
    public let deviceCenterActions: [DeviceCenterAction]
    
    public init(
        deviceListAssets: DeviceListAssets,
        backupListAssets: BackupListAssets,
        emptyStateAssets: EmptyStateAssets,
        searchAssets: SearchAssets,
        backupStatuses: [BackupStatus],
        deviceCenterActions: [DeviceCenterAction]
    ) {
        self.deviceListAssets = deviceListAssets
        self.backupListAssets = backupListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.backupStatuses = backupStatuses
        self.deviceCenterActions = deviceCenterActions
    }
}
