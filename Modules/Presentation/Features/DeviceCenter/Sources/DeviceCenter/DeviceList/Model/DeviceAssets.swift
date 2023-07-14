
public struct DeviceAssets {
    public let iconName: String
    public let status: BackupStatus
    
    public init(iconName: String, status: BackupStatus) {
        self.iconName = iconName
        self.status = status
    }
}
