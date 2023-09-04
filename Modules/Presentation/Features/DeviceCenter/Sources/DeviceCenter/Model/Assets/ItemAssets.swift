public struct ItemAssets {
    public let iconName: String
    public let backupStatus: BackupStatus
    public let defaultName: String?
    
    public init(
        iconName: String,
        status: BackupStatus,
        defaultName: String? = nil
    ) {
        self.iconName = iconName
        self.backupStatus = status
        self.defaultName = defaultName
    }
}
