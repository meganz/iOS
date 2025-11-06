import MEGADomain
import UIKit

public struct StatusAssets {
    public let title: String
    public let iconName: String
    public let color: UIColor
    
    public init(
        title: String,
        color: UIColor,
        iconName: String
    ) {
        self.title = title
        self.color = color
        self.iconName = iconName
    }
}
