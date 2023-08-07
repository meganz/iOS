import MEGADomain

public struct BackupStatus {
    public let status: BackupStatusEntity
    public let title: String
    public let colorName: String
    public let iconName: String
    
    public init(status: BackupStatusEntity, title: String, colorName: String, iconName: String) {
        self.status = status
        self.title = title
        self.colorName = colorName
        self.iconName = iconName
    }
}
