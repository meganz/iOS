import MEGAAssets
import MEGADesignToken

@objc enum BannerType: Int {
    case warning = 0
    
    var bgColor: UIColor {
        switch self {
        case .warning: TokenColors.Notifications.notificationWarning
        }
    }
    
    var darkBgColor: UIColor {
        switch self {
        case .warning: TokenColors.Notifications.notificationWarning
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .warning: TokenColors.Text.primary
        }
    }
    
    var darkTextColor: UIColor {
        switch self {
        case .warning: TokenColors.Text.primary
        }
    }
    
    var actionIcon: UIImage? {
        switch self {
        case .warning: 
            let image = MEGAAssets.UIImage.closeCircle.withRenderingMode(.alwaysTemplate)
            
            return image
        }
    }
}
