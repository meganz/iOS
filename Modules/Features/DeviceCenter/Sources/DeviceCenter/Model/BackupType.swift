import MEGADomain

public struct BackupType {
    public let type: BackupTypeEntity
    public let iconName: String
    
    public init(type: BackupTypeEntity, iconName: String) {
        self.type = type
        self.iconName = iconName
    }
}
