import MEGADomain
import UIKit

public struct BackupStatus {
    public let status: BackupStatusEntity
    public let title: String
    public let iconName: String
    public let color: UIColor
    
    public init(
        status: BackupStatusEntity,
        title: String,
        color: UIColor,
        iconName: String
    ) {
        self.status = status
        self.title = title
        self.color = color
        self.iconName = iconName
    }
}
