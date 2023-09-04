public struct BackupListAssets {
    public let backupTypes: [BackupType]
    
    public init(backupTypes: [BackupType]) {
        self.backupTypes = backupTypes
    }
}
