import MEGADomain

public struct DeviceCenterAssets {
    public let deviceListAssets: DeviceListAssets
    public let backupListAssets: BackupListAssets
    public let emptyStateAssets: EmptyStateAssets
    public let searchAssets: SearchAssets
    public let deviceCenterActions: [ContextAction]
    public let deviceIconNames: [BackupDeviceTypeEntity: String]
    
    public init(
        deviceListAssets: DeviceListAssets,
        backupListAssets: BackupListAssets,
        emptyStateAssets: EmptyStateAssets,
        searchAssets: SearchAssets,
        deviceCenterActions: [ContextAction],
        deviceIconNames: [BackupDeviceTypeEntity: String]
    ) {
        self.deviceListAssets = deviceListAssets
        self.backupListAssets = backupListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.deviceCenterActions = deviceCenterActions
        self.deviceIconNames = deviceIconNames
    }
}
