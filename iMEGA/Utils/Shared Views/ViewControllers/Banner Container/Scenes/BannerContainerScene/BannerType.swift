import MEGADesignToken

@objc enum BannerType: Int {
    case warning = 0
    
    var bgColor: UIColor {
        switch self {
        case .warning: return UIColor.isDesignTokenEnabled() ? TokenColors.Notifications.notificationWarning : UIColor.yellowFED429
        }
    }
    
    var darkBgColor: UIColor {
        switch self {
        case .warning: return UIColor.isDesignTokenEnabled() ? TokenColors.Notifications.notificationWarning : UIColor.brown544B27
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .warning: return UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.yellow9D8319
        }
    }
    
    var darkTextColor: UIColor {
        switch self {
        case .warning: return UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.yellowF8D552
        }
    }
    
    var actionIcon: UIImage? {
        switch self {
        case .warning: 
            let image = UIImage.closeCircle
            image.withRenderingMode(UIColor.isDesignTokenEnabled() ? .alwaysTemplate : .alwaysOriginal)
            
            return image
        }
    }
}
